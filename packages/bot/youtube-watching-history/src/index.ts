import { YouTubeBot } from "./services/YouTubeBot";
import "dotenv/config";
import * as fs from "fs";
import * as path from "path";
import dotenv from 'dotenv';
import { YouTubeTokenManager } from './services/YouTubeTokenManager';
import { YouTubeAPIService } from './services/YouTubeAPIService';

dotenv.config();

const {
  YOUTUBE_CLIENT_ID,
  YOUTUBE_CLIENT_SECRET,
  YOUTUBE_REDIRECT_URI,
  SUPABASE_URL,
  SUPABASE_KEY
} = process.env;

if (!YOUTUBE_CLIENT_ID || !YOUTUBE_CLIENT_SECRET || !YOUTUBE_REDIRECT_URI || !SUPABASE_URL || !SUPABASE_KEY) {
  throw new Error('필수 환경 변수가 설정되지 않았습니다.');
}

const tokenManager = new YouTubeTokenManager(
  YOUTUBE_CLIENT_ID,
  YOUTUBE_CLIENT_SECRET,
  YOUTUBE_REDIRECT_URI,
  SUPABASE_URL,
  SUPABASE_KEY
);

const youtubeService = new YouTubeAPIService(tokenManager);

async function main() {
  const bot = new YouTubeBot();

  try {
    console.log("YouTubeBot 초기화 시작");
    await bot.init();
    console.log("YouTubeBot 초기화 완료");
    console.log("로그인 시작");
    await bot.login();
    console.log("로그인 완료");

    // keywords.json 파일에서 키워드 배열 읽기
    const keywordsPath = path.join(__dirname, "keywords.json");
    const keywords = JSON.parse(fs.readFileSync(keywordsPath, "utf-8"));

    while (true) {
      const randomKeyword =
        keywords[Math.floor(Math.random() * keywords.length)];
      console.log(`\n새로운 검색 시작... ${randomKeyword}`);
      await bot.searchAndAnalyze(randomKeyword);

      // 다음 검색 전에 잠시 대기
      console.log("다음 검색을 위해 3초 대기...");
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
  } catch (error) {
    console.error("Error:", error);
  } finally {
    await bot.close();
  }
}

// 예제: 채널 구독 및 동영상 상호작용
async function interactWithChannel(accountId: string, channelId: string) {
  try {
    // 채널 정보 가져오기
    const channelInfo = await youtubeService.getChannelInfo(accountId, channelId);
    console.log('채널 정보:', {
      title: channelInfo.snippet?.title,
      subscriberCount: channelInfo.statistics?.subscriberCount
    });

    // 구독 상태 확인
    const isSubscribed = await youtubeService.isSubscribed(accountId, channelId);
    console.log('구독 상태:', isSubscribed ? '구독 중' : '미구독');

    // 미구독 상태면 구독
    if (!isSubscribed) {
      const subscribed = await youtubeService.subscribeToChannel(accountId, channelId);
      console.log('구독 시도 결과:', subscribed ? '성공' : '실패');
    }

    // 채널의 최근 동영상 가져오기
    const videos = await youtubeService.getChannelVideos(accountId, channelId, 5);
    console.log('최근 동영상:', videos.map(video => ({
      title: video.snippet?.title,
      viewCount: video.statistics?.viewCount
    })));

    // 첫 번째 동영상에 좋아요 및 댓글
    if (videos.length > 0) {
      const videoId = videos[0].id;
      if (videoId) {
        // 좋아요
        const liked = await youtubeService.likeVideo(accountId, videoId);
        console.log('좋아요 시도 결과:', liked ? '성공' : '실패');

        // 동영상 설명 가져오기
        const description = await youtubeService.getVideoDescription(accountId, videoId);
        console.log('동영상 설명:', description.substring(0, 100) + '...');

        // 댓글 작성
        const commentPosted = await youtubeService.postComment(
          accountId,
          videoId,
          '좋은 영상이네요! 구독하고 갑니다~'
        );
        console.log('댓글 작성 결과:', commentPosted ? '성공' : '실패');
      }
    }
  } catch (error) {
    console.error('채널 상호작용 중 오류 발생:', error);
  }
}

// 사용 예시
const accountId = 'test-account-1';
const channelId = 'UC_x5XG1OV2P6uZZ5FSM9Ttw'; // Google Developers 채널

interactWithChannel(accountId, channelId)
  .then(() => console.log('작업 완료'))
  .catch(error => console.error('작업 중 오류 발생:', error));

main();