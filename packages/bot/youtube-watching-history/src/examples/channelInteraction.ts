import { YouTubeChannelBot } from '../services/YouTubeChannelBot';

async function main() {
  const bot = new YouTubeChannelBot();
  
  try {
    // 브라우저 초기화
    await bot.init();
    
    // 로그인
    await bot.login();
    
    // 채널 구독
    const channelUrl = 'https://www.youtube.com/channel/채널ID';
    await bot.subscribeToChannel(channelUrl);
    
    // 동영상 상호작용
    const videoUrl = 'https://www.youtube.com/watch?v=동영상ID';
    await bot.interactWithVideo(videoUrl);
    
  } catch (error) {
    console.error('오류 발생:', error);
  } finally {
    // 브라우저 종료
    await bot.close();
  }
}

main(); 