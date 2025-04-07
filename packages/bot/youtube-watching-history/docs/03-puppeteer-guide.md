# 3. Puppeteer 구현 가이드

## 목차
1. [Puppeteer 설정](#puppeteer-설정)
2. [브라우저 자동화 구현](#브라우저-자동화-구현)
3. [시청 이력 관리](#시청-이력-관리)
4. [에러 처리 및 재시도](#에러-처리-및-재시도)
5. [테스트 작성](#테스트-작성)

## Puppeteer 설정

### 1. Puppeteer 설치
```bash
npm install puppeteer
```

### 2. 브라우저 설정 클래스
```typescript
// src/config/browser.ts
import puppeteer, { Browser, Page } from 'puppeteer';

export class BrowserConfig {
  static async launchBrowser(): Promise<Browser> {
    return await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--window-size=1920x1080'
      ]
    });
  }

  static async createPage(browser: Browser): Promise<Page> {
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    return page;
  }
}
```

## 브라우저 자동화 구현

### 1. YouTube 시청 서비스
```typescript
// src/services/YouTubeWatchService.ts
import { Browser, Page } from 'puppeteer';
import { BrowserConfig } from '../config/browser';

export class YouTubeWatchService {
  private browser: Browser | null = null;
  private page: Page | null = null;

  async initialize(): Promise<void> {
    this.browser = await BrowserConfig.launchBrowser();
    this.page = await BrowserConfig.createPage(this.browser);
  }

  async login(email: string, password: string): Promise<void> {
    if (!this.page) throw new Error('페이지가 초기화되지 않았습니다.');

    try {
      await this.page.goto('https://accounts.google.com/signin');
      
      // 이메일 입력
      await this.page.waitForSelector('input[type="email"]');
      await this.page.type('input[type="email"]', email);
      await this.page.click('#identifierNext');

      // 비밀번호 입력
      await this.page.waitForSelector('input[type="password"]');
      await this.page.type('input[type="password"]', password);
      await this.page.click('#passwordNext');

      // 로그인 완료 대기
      await this.page.waitForNavigation();
    } catch (error) {
      console.error('로그인 실패:', error);
      throw error;
    }
  }

  async watchVideo(videoId: string, duration: number): Promise<void> {
    if (!this.page) throw new Error('페이지가 초기화되지 않았습니다.');

    try {
      // 동영상 페이지로 이동
      await this.page.goto(`https://www.youtube.com/watch?v=${videoId}`);
      
      // 동영상 로드 대기
      await this.page.waitForSelector('video');
      
      // 동영상 자동 재생 시작
      await this.page.evaluate(() => {
        const video = document.querySelector('video');
        if (video) {
          video.play();
          video.muted = true; // 음소거
        }
      });

      // 지정된 시간 동안 시청
      await new Promise(resolve => setTimeout(resolve, duration * 1000));

      // 시청 완료 후 이력 저장
      await this.saveWatchHistory(videoId, duration);
    } catch (error) {
      console.error('동영상 시청 실패:', error);
      throw error;
    }
  }

  private async saveWatchHistory(videoId: string, duration: number): Promise<void> {
    // Supabase에 시청 이력 저장
    const { error } = await supabase
      .from('watch_logs')
      .insert({
        video_id: videoId,
        watch_duration: duration,
        watch_date: new Date()
      });

    if (error) throw error;
  }

  async close(): Promise<void> {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
      this.page = null;
    }
  }
}
```

### 2. 동영상 정보 수집 서비스
```typescript
// src/services/VideoInfoService.ts
import { Page } from 'puppeteer';

export class VideoInfoService {
  constructor(private page: Page) {}

  async getVideoDescription(): Promise<string> {
    try {
      await this.page.waitForSelector('#description');
      return await this.page.$eval('#description', el => el.textContent || '');
    } catch (error) {
      console.error('동영상 설명 수집 실패:', error);
      throw error;
    }
  }

  async getVideoMetadata(): Promise<{
    title: string;
    channelName: string;
    viewCount: string;
    uploadDate: string;
  }> {
    try {
      const metadata = await this.page.evaluate(() => {
        return {
          title: document.querySelector('h1.title')?.textContent || '',
          channelName: document.querySelector('#channel-name a')?.textContent || '',
          viewCount: document.querySelector('#count .view-count')?.textContent || '',
          uploadDate: document.querySelector('#date .date')?.textContent || ''
        };
      });

      return metadata;
    } catch (error) {
      console.error('동영상 메타데이터 수집 실패:', error);
      throw error;
    }
  }
}
```

## 시청 이력 관리

### 1. 시청 이력 서비스
```typescript
// src/services/WatchHistoryService.ts
import { createClient } from '@supabase/supabase-js';

export class WatchHistoryService {
  private supabase;

  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!
    );
  }

  async getWatchHistory(accountId: string, limit: number = 10): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('watch_logs')
      .select('*')
      .eq('account_id', accountId)
      .order('watch_date', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async saveWatchHistory(
    accountId: string,
    videoId: string,
    duration: number
  ): Promise<void> {
    const { error } = await this.supabase
      .from('watch_logs')
      .insert({
        account_id: accountId,
        video_id: videoId,
        watch_duration: duration,
        watch_date: new Date()
      });

    if (error) throw error;
  }
}
```

## 에러 처리 및 재시도

### 1. Puppeteer 에러 처리
```typescript
// src/utils/puppeteerErrorHandler.ts
export class PuppeteerError extends Error {
  constructor(
    message: string,
    public type: 'LOGIN' | 'NAVIGATION' | 'SELECTOR' | 'TIMEOUT',
    public originalError?: any
  ) {
    super(message);
    this.name = 'PuppeteerError';
  }
}

export function handlePuppeteerError(error: any): never {
  if (error.name === 'TimeoutError') {
    throw new PuppeteerError('작업 시간 초과', 'TIMEOUT', error);
  }
  
  if (error.message.includes('No node found for selector')) {
    throw new PuppeteerError('요소를 찾을 수 없음', 'SELECTOR', error);
  }

  throw new PuppeteerError(error.message, 'NAVIGATION', error);
}
```

### 2. 재시도 로직
```typescript
// src/utils/retryPuppeteer.ts
import { retry } from './retry';
import { handlePuppeteerError } from './puppeteerErrorHandler';

export async function retryPuppeteer<T>(
  fn: () => Promise<T>,
  maxAttempts: number = 3,
  delayMs: number = 2000
): Promise<T> {
  return retry(
    async () => {
      try {
        return await fn();
      } catch (error) {
        throw handlePuppeteerError(error);
      }
    },
    maxAttempts,
    delayMs
  );
}
```

## 테스트 작성

### 1. 시청 서비스 테스트
```typescript
// tests/unit/YouTubeWatchService.test.ts
import { YouTubeWatchService } from '../../src/services/YouTubeWatchService';

describe('YouTubeWatchService', () => {
  let watchService: YouTubeWatchService;

  beforeEach(async () => {
    watchService = new YouTubeWatchService();
    await watchService.initialize();
  });

  afterEach(async () => {
    await watchService.close();
  });

  it('동영상 시청이 성공해야 함', async () => {
    await expect(watchService.watchVideo('test-video-id', 10))
      .resolves.not.toThrow();
  });

  it('시청 이력이 저장되어야 함', async () => {
    const videoId = 'test-video-id';
    const duration = 10;
    
    await watchService.watchVideo(videoId, duration);
    
    const { data } = await supabase
      .from('watch_logs')
      .select('*')
      .eq('video_id', videoId)
      .single();

    expect(data).toBeDefined();
    expect(data.watch_duration).toBe(duration);
  });
});
```

### 2. 정보 수집 서비스 테스트
```typescript
// tests/unit/VideoInfoService.test.ts
import { VideoInfoService } from '../../src/services/VideoInfoService';

describe('VideoInfoService', () => {
  let infoService: VideoInfoService;
  let page: Page;

  beforeEach(async () => {
    const browser = await BrowserConfig.launchBrowser();
    page = await BrowserConfig.createPage(browser);
    infoService = new VideoInfoService(page);
  });

  afterEach(async () => {
    await page.browser().close();
  });

  it('동영상 설명을 수집해야 함', async () => {
    await page.goto('https://www.youtube.com/watch?v=test-video-id');
    const description = await infoService.getVideoDescription();
    expect(description).toBeDefined();
    expect(typeof description).toBe('string');
  });

  it('동영상 메타데이터를 수집해야 함', async () => {
    await page.goto('https://www.youtube.com/watch?v=test-video-id');
    const metadata = await infoService.getVideoMetadata();
    expect(metadata).toBeDefined();
    expect(metadata.title).toBeDefined();
    expect(metadata.channelName).toBeDefined();
  });
});
```

## 다음 단계
- [AWS 서비스 설정 가이드](../docs/04-aws-guide.md)로 이동 