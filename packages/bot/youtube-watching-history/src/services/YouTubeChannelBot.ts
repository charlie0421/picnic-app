import { YouTubeBot } from './YouTubeBot';
import { OpenAIService } from './OpenAIService';
import puppeteer, { Page } from 'puppeteer';

export class YouTubeChannelBot extends YouTubeBot {
  private openAIService: OpenAIService;

  constructor() {
    super();
    this.openAIService = new OpenAIService();
  }

  async subscribeToChannel(channelUrl: string): Promise<boolean> {
    if (!this.page) {
      throw new Error('브라우저가 초기화되지 않았습니다.');
    }

    try {
      console.log(`채널 방문: ${channelUrl}`);
      await this.page.goto(channelUrl, { waitUntil: 'networkidle0' });
      await this.sleep(2000);

      // 구독 버튼 찾기
      const subscribeButton = await this.page.waitForSelector('ytd-subscribe-button-renderer', {
        timeout: 5000,
      });

      if (!subscribeButton) {
        console.log('구독 버튼을 찾을 수 없습니다.');
        return false;
      }

      // 구독 상태 확인
      const isSubscribed = await this.page.evaluate(() => {
        const button = document.querySelector('ytd-subscribe-button-renderer');
        return button?.getAttribute('subscribed') === 'true';
      });

      if (isSubscribed) {
        console.log('이미 구독 중인 채널입니다.');
        return true;
      }

      // 구독 버튼 클릭
      await subscribeButton.click();
      console.log('채널 구독 완료');
      await this.sleep(2000);

      return true;
    } catch (error) {
      console.error('채널 구독 중 오류 발생:', error);
      return false;
    }
  }

  async interactWithVideo(videoUrl: string): Promise<boolean> {
    if (!this.page) {
      throw new Error('브라우저가 초기화되지 않았습니다.');
    }

    try {
      console.log(`동영상 방문: ${videoUrl}`);
      await this.page.goto(videoUrl, { waitUntil: 'networkidle0' });
      await this.sleep(2000);

      // 좋아요 버튼 클릭
      const likeButton = await this.page.waitForSelector('ytd-menu-renderer.ytd-video-primary-info-renderer button[aria-label*="좋아요"]', {
        timeout: 5000,
      });

      if (likeButton) {
        await likeButton.click();
        console.log('좋아요 클릭 완료');
        await this.sleep(1000);
      }

      // 동영상 설명 가져오기
      const description = await this.page.evaluate(() => {
        const descriptionElement = document.querySelector('ytd-video-description-renderer #description');
        return descriptionElement?.textContent || '';
      });

      // OpenAI를 사용하여 댓글 생성
      const comment = await this.openAIService.generateComment(description);

      // 댓글 입력
      const commentBox = await this.page.waitForSelector('#simplebox-placeholder', {
        timeout: 5000,
      });

      if (commentBox) {
        await commentBox.click();
        await this.sleep(1000);

        // 댓글 입력 필드 찾기
        const commentInput = await this.page.waitForSelector('#contenteditable-textarea', {
          timeout: 5000,
        });

        if (commentInput) {
          await commentInput.type(comment, { delay: 100 });
          await this.sleep(1000);

          // 댓글 게시 버튼 클릭
          const submitButton = await this.page.waitForSelector('#submit-button', {
            timeout: 5000,
          });

          if (submitButton) {
            await submitButton.click();
            console.log('댓글 게시 완료');
            await this.sleep(2000);
          }
        }
      }

      return true;
    } catch (error) {
      console.error('동영상 상호작용 중 오류 발생:', error);
      return false;
    }
  }
} 