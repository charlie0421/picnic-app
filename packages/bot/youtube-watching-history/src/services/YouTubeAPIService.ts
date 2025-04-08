import { youtube_v3 } from '@googleapis/youtube';
import { OAuth2Client } from 'google-auth-library';
import { YouTubeTokenManager } from './YouTubeTokenManager';

export class YouTubeAPIService {
  private youtube: youtube_v3.Youtube;
  private tokenManager: YouTubeTokenManager;

  constructor(tokenManager: YouTubeTokenManager) {
    this.tokenManager = tokenManager;
    this.youtube = new youtube_v3.Youtube({
      auth: new OAuth2Client()
    });
  }

  private async setAuth(accountId: string): Promise<void> {
    const tokenData = await this.tokenManager.getToken(accountId);
    (this.youtube.auth as OAuth2Client).setCredentials({
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token
    });
  }

  async subscribeToChannel(accountId: string, channelId: string): Promise<boolean> {
    try {
      await this.setAuth(accountId);

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

      console.log(`채널 구독 성공 (계정 ID: ${accountId}, 채널 ID: ${channelId})`);
      return true;
    } catch (error) {
      console.error(`채널 구독 실패 (계정 ID: ${accountId}):`, error);
      return false;
    }
  }

  async likeVideo(accountId: string, videoId: string): Promise<boolean> {
    try {
      await this.setAuth(accountId);

      await this.youtube.videos.rate({
        id: videoId,
        rating: 'like'
      });

      console.log(`동영상 좋아요 성공 (계정 ID: ${accountId}, 동영상 ID: ${videoId})`);
      return true;
    } catch (error) {
      console.error(`동영상 좋아요 실패 (계정 ID: ${accountId}):`, error);
      return false;
    }
  }

  async postComment(accountId: string, videoId: string, text: string): Promise<boolean> {
    try {
      await this.setAuth(accountId);

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

      console.log(`댓글 작성 성공 (계정 ID: ${accountId}, 동영상 ID: ${videoId})`);
      return true;
    } catch (error) {
      console.error(`댓글 작성 실패 (계정 ID: ${accountId}):`, error);
      return false;
    }
  }

  async getVideoDescription(accountId: string, videoId: string): Promise<string> {
    try {
      await this.setAuth(accountId);

      const response = await this.youtube.videos.list({
        part: ['snippet'],
        id: [videoId]
      });

      const description = response.data.items?.[0]?.snippet?.description || '';
      return description;
    } catch (error) {
      console.error(`동영상 설명 가져오기 실패 (계정 ID: ${accountId}):`, error);
      throw error;
    }
  }

  async getChannelVideos(accountId: string, channelId: string, maxResults: number = 10): Promise<youtube_v3.Schema$Video[]> {
    try {
      await this.setAuth(accountId);

      const response = await this.youtube.search.list({
        part: ['snippet'],
        channelId: channelId,
        maxResults: maxResults,
        order: 'date',
        type: ['video']
      });

      const videoIds = response.data.items?.map(item => item.id?.videoId).filter(Boolean) as string[];
      
      if (!videoIds.length) {
        return [];
      }

      const videosResponse = await this.youtube.videos.list({
        part: ['snippet', 'statistics'],
        id: videoIds
      });

      return videosResponse.data.items || [];
    } catch (error) {
      console.error(`채널 동영상 목록 가져오기 실패 (계정 ID: ${accountId}):`, error);
      throw error;
    }
  }

  async getChannelInfo(accountId: string, channelId: string): Promise<youtube_v3.Schema$Channel> {
    try {
      await this.setAuth(accountId);

      const response = await this.youtube.channels.list({
        part: ['snippet', 'statistics'],
        id: [channelId]
      });

      const channel = response.data.items?.[0];
      if (!channel) {
        throw new Error('채널을 찾을 수 없습니다.');
      }

      return channel;
    } catch (error) {
      console.error(`채널 정보 가져오기 실패 (계정 ID: ${accountId}):`, error);
      throw error;
    }
  }

  async isSubscribed(accountId: string, channelId: string): Promise<boolean> {
    try {
      await this.setAuth(accountId);

      const response = await this.youtube.subscriptions.list({
        part: ['snippet'],
        forChannelId: channelId,
        mine: true,
        maxResults: 1
      });

      return (response.data.items?.length || 0) > 0;
    } catch (error) {
      console.error(`구독 상태 확인 실패 (계정 ID: ${accountId}):`, error);
      throw error;
    }
  }
} 