import { OAuth2Client } from 'google-auth-library';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

interface TokenData {
  access_token: string;
  refresh_token: string;
  expiry_date: number;
  scope: string;
}

export class YouTubeTokenManager {
  private oauth2Client: OAuth2Client;
  private supabase: SupabaseClient;

  constructor(
    clientId: string,
    clientSecret: string,
    redirectUri: string,
    supabaseUrl: string,
    supabaseKey: string
  ) {
    this.oauth2Client = new OAuth2Client(
      clientId,
      clientSecret,
      redirectUri
    );
    this.supabase = createClient(supabaseUrl, supabaseKey);
  }

  async generateAuthUrl(accountId: string): Promise<string> {
    const scopes = [
      'https://www.googleapis.com/auth/youtube',
      'https://www.googleapis.com/auth/youtube.force-ssl'
    ];

    const url = this.oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: scopes,
      prompt: 'consent',
      state: accountId
    });

    return url;
  }

  async handleAuthCallback(code: string, accountId: string): Promise<void> {
    try {
      const { tokens } = await this.oauth2Client.getToken(code);
      
      if (!tokens.access_token || !tokens.refresh_token || !tokens.expiry_date) {
        throw new Error('필수 토큰 정보가 누락되었습니다.');
      }

      await this.supabase
        .from('youtube_tokens')
        .upsert({
          account_id: accountId,
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          expiry_date: tokens.expiry_date,
          scope: tokens.scope,
          updated_at: new Date().toISOString()
        });

      console.log(`토큰이 성공적으로 저장되었습니다. (계정 ID: ${accountId})`);
    } catch (error) {
      console.error('토큰 저장 중 오류 발생:', error);
      throw error;
    }
  }

  async refreshToken(accountId: string): Promise<void> {
    try {
      const { data: tokenData, error } = await this.supabase
        .from('youtube_tokens')
        .select('*')
        .eq('account_id', accountId)
        .single();

      if (error) {
        throw error;
      }

      if (!tokenData) {
        throw new Error('토큰을 찾을 수 없습니다.');
      }

      this.oauth2Client.setCredentials({
        refresh_token: tokenData.refresh_token
      });

      const { credentials } = await this.oauth2Client.refreshAccessToken();
      
      if (!credentials.access_token || !credentials.expiry_date) {
        throw new Error('갱신된 토큰 정보가 누락되었습니다.');
      }

      await this.supabase
        .from('youtube_tokens')
        .update({
          access_token: credentials.access_token,
          expiry_date: credentials.expiry_date,
          updated_at: new Date().toISOString()
        })
        .eq('account_id', accountId);

      console.log(`토큰이 성공적으로 갱신되었습니다. (계정 ID: ${accountId})`);
    } catch (error) {
      console.error('토큰 갱신 중 오류 발생:', error);
      throw error;
    }
  }

  async getToken(accountId: string): Promise<TokenData> {
    const { data: tokenData, error } = await this.supabase
      .from('youtube_tokens')
      .select('*')
      .eq('account_id', accountId)
      .single();

    if (error) {
      throw error;
    }

    if (!tokenData) {
      throw new Error('토큰을 찾을 수 없습니다.');
    }

    if (Date.now() >= tokenData.expiry_date) {
      await this.refreshToken(accountId);
      return this.getToken(accountId);
    }

    return tokenData;
  }
} 