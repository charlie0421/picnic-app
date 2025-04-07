# 2. YouTube API 구현 가이드

## 목차
1. [OAuth 2.0 인증 구현](#oauth-20-인증-구현)
2. [토큰 관리 서비스 구현](#토큰-관리-서비스-구현)
3. [YouTube API 서비스 구현](#youtube-api-서비스-구현)
4. [에러 처리 및 재시도 로직](#에러-처리-및-재시도-로직)
5. [테스트 작성](#테스트-작성)

## OAuth 2.0 인증 구현

### 1. OAuth 클라이언트 설정
```typescript
// src/config/oauth.ts
import { OAuth2Client } from 'google-auth-library';

export const oauth2Client = new OAuth2Client(
  process.env.YOUTUBE_CLIENT_ID,
  process.env.YOUTUBE_CLIENT_SECRET,
  process.env.YOUTUBE_REDIRECT_URI
);
```

### 2. 인증 URL 생성
```typescript
// src/services/YouTubeAuthService.ts
import { oauth2Client } from '../config/oauth';

export class YouTubeAuthService {
  static generateAuthUrl(accountId: string): string {
    const scopes = [
      'https://www.googleapis.com/auth/youtube',
      'https://www.googleapis.com/auth/youtube.force-ssl'
    ];

    return oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: scopes,
      state: accountId,
      prompt: 'consent'
    });
  }
}
```

### 3. 콜백 처리
```typescript
// src/services/YouTubeAuthService.ts
export class YouTubeAuthService {
  static async handleCallback(code: string, accountId: string): Promise<void> {
    try {
      const { tokens } = await oauth2Client.getToken(code);
      
      if (!tokens.access_token || !tokens.refresh_token) {
        throw new Error('토큰 정보가 누락되었습니다.');
      }

      // Supabase에 토큰 저장
      await this.saveTokens(accountId, tokens);
    } catch (error) {
      console.error('토큰 획득 실패:', error);
      throw error;
    }
  }

  private static async saveTokens(accountId: string, tokens: any): Promise<void> {
    const { data, error } = await supabase
      .from('youtube_tokens')
      .upsert({
        account_id: accountId,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expiry_date: new Date(Date.now() + (tokens.expiry_date || 3600) * 1000)
      });

    if (error) throw error;
  }
}
```

## 토큰 관리 서비스 구현

### 1. 토큰 관리자 클래스
```typescript
// src/services/YouTubeTokenManager.ts
import { OAuth2Client } from 'google-auth-library';
import { createClient } from '@supabase/supabase-js';

export class YouTubeTokenManager {
  private supabase;
  private oauth2Client: OAuth2Client;

  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!
    );
    this.oauth2Client = new OAuth2Client(
      process.env.YOUTUBE_CLIENT_ID,
      process.env.YOUTUBE_CLIENT_SECRET,
      process.env.YOUTUBE_REDIRECT_URI
    );
  }

  async getToken(accountId: string): Promise<string> {
    const { data, error } = await this.supabase
      .from('youtube_tokens')
      .select('*')
      .eq('account_id', accountId)
      .single();

    if (error || !data) {
      throw new Error('토큰을 찾을 수 없습니다.');
    }

    if (this.isTokenExpired(data.expiry_date)) {
      return await this.refreshToken(data.refresh_token, accountId);
    }

    return data.access_token;
  }

  private async refreshToken(refreshToken: string, accountId: string): Promise<string> {
    this.oauth2Client.setCredentials({ refresh_token: refreshToken });
    
    const { credentials } = await this.oauth2Client.refreshAccessToken();
    
    if (!credentials.access_token) {
      throw new Error('토큰 갱신 실패');
    }

    await this.saveTokens(accountId, credentials);
    return credentials.access_token;
  }

  private isTokenExpired(expiryDate: string): boolean {
    return new Date(expiryDate) <= new Date();
  }
}
```

## YouTube API 서비스 구현

### 1. API 서비스 클래스
```typescript
// src/services/YouTubeAPIService.ts
import { youtube_v3 } from 'googleapis';
import { YouTubeTokenManager } from './YouTubeTokenManager';

export class YouTubeAPIService {
  private tokenManager: YouTubeTokenManager;
  private youtube: youtube_v3.Youtube;

  constructor() {
    this.tokenManager = new YouTubeTokenManager();
    this.youtube = new youtube_v3.Youtube();
  }

  async setAuth(accountId: string): Promise<void> {
    const token = await this.tokenManager.getToken(accountId);
    this.youtube = new youtube_v3.Youtube({
      auth: new google.auth.OAuth2(
        process.env.YOUTUBE_CLIENT_ID,
        process.env.YOUTUBE_CLIENT_SECRET,
        process.env.YOUTUBE_REDIRECT_URI
      )
    });
    this.youtube.setCredentials({ access_token: token });
  }

  async subscribeToChannel(channelId: string): Promise<void> {
    try {
      await this.youtube.subscriptions.insert({
        part: ['snippet'],
        requestBody: {
          snippet: {
            resourceId: {
              kind: 'youtube#channel',
              channelId: channelId
            }
          }
        }
      });
    } catch (error) {
      console.error('채널 구독 실패:', error);
      throw error;
    }
  }

  async likeVideo(videoId: string): Promise<void> {
    try {
      await this.youtube.videos.rate({
        id: videoId,
        rating: 'like'
      });
    } catch (error) {
      console.error('좋아요 실패:', error);
      throw error;
    }
  }

  async postComment(videoId: string, text: string): Promise<void> {
    try {
      await this.youtube.commentThreads.insert({
        part: ['snippet'],
        requestBody: {
          snippet: {
            videoId: videoId,
            topLevelComment: {
              snippet: {
                textOriginal: text
              }
            }
          }
        }
      });
    } catch (error) {
      console.error('댓글 작성 실패:', error);
      throw error;
    }
  }
}
```

## 에러 처리 및 재시도 로직

### 1. 재시도 유틸리티
```typescript
// src/utils/retry.ts
export async function retry<T>(
  fn: () => Promise<T>,
  maxAttempts: number = 3,
  delayMs: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (attempt < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, delayMs * attempt));
      }
    }
  }

  throw lastError;
}
```

### 2. 에러 처리 미들웨어
```typescript
// src/utils/errorHandler.ts
export class YouTubeAPIError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public originalError?: any
  ) {
    super(message);
    this.name = 'YouTubeAPIError';
  }
}

export function handleYouTubeError(error: any): never {
  if (error.response) {
    throw new YouTubeAPIError(
      error.response.data.error.message,
      error.response.status,
      error
    );
  }
  throw new YouTubeAPIError(error.message, 500, error);
}
```

## 테스트 작성

### 1. 토큰 관리자 테스트
```typescript
// tests/unit/YouTubeTokenManager.test.ts
import { YouTubeTokenManager } from '../../src/services/YouTubeTokenManager';

describe('YouTubeTokenManager', () => {
  let tokenManager: YouTubeTokenManager;

  beforeEach(() => {
    tokenManager = new YouTubeTokenManager();
  });

  it('토큰을 성공적으로 가져와야 함', async () => {
    const token = await tokenManager.getToken('test-account-id');
    expect(token).toBeDefined();
    expect(typeof token).toBe('string');
  });

  it('만료된 토큰을 갱신해야 함', async () => {
    // 만료된 토큰을 Supabase에 저장
    await supabase.from('youtube_tokens').upsert({
      account_id: 'test-account-id',
      access_token: 'expired-token',
      refresh_token: 'valid-refresh-token',
      expiry_date: new Date(Date.now() - 1000)
    });

    const token = await tokenManager.getToken('test-account-id');
    expect(token).toBeDefined();
    expect(token).not.toBe('expired-token');
  });
});
```

### 2. API 서비스 테스트
```typescript
// tests/unit/YouTubeAPIService.test.ts
import { YouTubeAPIService } from '../../src/services/YouTubeAPIService';

describe('YouTubeAPIService', () => {
  let apiService: YouTubeAPIService;

  beforeEach(() => {
    apiService = new YouTubeAPIService();
  });

  it('채널 구독이 성공해야 함', async () => {
    await apiService.setAuth('test-account-id');
    await expect(apiService.subscribeToChannel('test-channel-id'))
      .resolves.not.toThrow();
  });

  it('동영상 좋아요가 성공해야 함', async () => {
    await apiService.setAuth('test-account-id');
    await expect(apiService.likeVideo('test-video-id'))
      .resolves.not.toThrow();
  });
});
```

## 다음 단계
- [Puppeteer 구현 가이드](../docs/03-puppeteer-guide.md)로 이동 