import puppeteer, { Browser, Page } from "puppeteer";
import * as fs from 'fs';
import * as path from 'path';

// canvas 설정
const canvas = require("canvas");

export class YouTubeBot {
  private browser: Browser | null = null;
  private page: Page | null = null;
  private credentials: { email: string; password: string } | null = null;
  private watchedVideos: Map<string, { title: string; timestamp: number }> = new Map();

  private loadCredentials() {
    try {
      const credentialsPath = path.join(__dirname, '../config/credentials.json');
      const credentialsData = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
      this.credentials = credentialsData.youtube;
    } catch (error) {
      throw new Error('Failed to load credentials from file');
    }
  }

  async init() {
    this.browser = await puppeteer.launch({
      headless: false,
      defaultViewport: null,
      executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      args: [
        "--start-maximized",
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-blink-features=AutomationControlled",
        "--disable-dev-shm-usage",
        "--disable-accelerated-2d-canvas",
        "--disable-gpu",
        "--window-size=1920,1080",
        "--disable-web-security",
        "--disable-features=IsolateOrigins,site-per-process",
        "--disable-site-isolation-trials",
        "--disable-blink-features=AutomationControlled",
        "--disable-infobars",
        "--window-position=0,0",
        "--ignore-certifcate-errors",
        "--ignore-certifcate-errors-spki-list",
        "--enable-logging",
        "--v=1"
      ],
      ignoreDefaultArgs: ["--enable-automation"],
    });

    this.page = await this.browser.newPage();

    // 로그 파일 생성 경로 설정
    const logFilePath = path.join(__dirname, 'youtube_bot.log');
    console.log(`로그 파일 경로: ${logFilePath}`);

    try {
      // 로그 파일 생성
      const logFile = fs.createWriteStream(logFilePath, { flags: 'a' });
      console.log('로그 파일이 생성되었습니다.');

      // 브라우저 콘솔 로그 캡처 및 파일에 저장
      this.page.on('console', msg => {
        const logMessage = `[${new Date().toISOString()}] 브라우저 콘솔: ${msg.text()}\n`;
        console.log(logMessage.trim());
        logFile.write(logMessage);
      });
    } catch (error) {
      console.error('로그 파일 생성 중 오류 발생:', error);
    }

    // 자동화 감지 우회
    await this.page.evaluateOnNewDocument(() => {
      // 웹드라이버 감지 우회
      Object.defineProperty(navigator, 'webdriver', { get: () => false });
      
      // 크롬 런타임 속성 추가
      Object.defineProperty(navigator, 'chrome', {
        get: () => ({
          runtime: {},
          app: {
            isInstalled: false,
            InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' },
            RunningState: { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' }
          },
          loadTimes: () => {},
          csi: () => {},
          webstore: {}
        })
      });

      // 플랫폼 설정
      Object.defineProperty(navigator, 'platform', { get: () => 'MacIntel' });
      
      // 언어 설정
      Object.defineProperty(navigator, 'languages', { get: () => ['ko-KR', 'ko', 'en-US', 'en'] });
      
      // 플러그인 설정
      Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
      
      // 하드웨어 동시성 설정
      Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 8 });
      
      // 디바이스 메모리 설정
      Object.defineProperty(navigator, 'deviceMemory', { get: () => 8 });
      
      // 화면 해상도 설정
      Object.defineProperty(window, 'screen', {
        get: () => ({
          width: 1920,
          height: 1080,
          colorDepth: 24,
          pixelDepth: 24,
          availWidth: 1920,
          availHeight: 1080
        })
      });

      // 마우스 이벤트 감지 우회
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({
            state: Notification.permission,
            name: 'notifications',
            onchange: null,
            addEventListener: () => {},
            removeEventListener: () => {},
            dispatchEvent: () => true
          } as PermissionStatus) :
          originalQuery(parameters)
      );
    });

    // 랜덤한 사용자 에이전트 설정
    const userAgents = [
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
    ];
    await this.page.setUserAgent(userAgents[Math.floor(Math.random() * userAgents.length)]);

    // 추가 헤더 설정
    await this.page.setExtraHTTPHeaders({
      'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'sec-ch-ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"macOS"'
    });

    await this.page.setViewport({ width: 1920, height: 1080 });
  }

  async login() {
    if (!this.page) throw new Error("Browser not initialized");
    
    if (!this.credentials) {
      this.loadCredentials();
    }

    if (!this.credentials?.email || !this.credentials?.password) {
      throw new Error("YouTube credentials not found in credentials file");
    }

    try {
      // YouTube 메인으로 이동
      await this.page.goto("https://www.youtube.com", { 
        waitUntil: 'networkidle0',
        timeout: 30000
      });
      await this.sleep(2000);

      // 로그인 버튼 클릭
      const loginButton = await this.page.waitForSelector('a[href*="accounts.google.com"]', { 
        timeout: 5000,
        visible: true 
      });
      
      if (!loginButton) {
        // 이미 로그인된 상태일 수 있음
        const avatar = await this.page.waitForSelector("#avatar-btn", { timeout: 5000 });
        if (avatar) {
          console.log("이미 로그인된 상태입니다.");
          return;
        }
        throw new Error("로그인 버튼을 찾을 수 없습니다.");
      }

      // 로그인 버튼 클릭
      await loginButton.click();
      await this.sleep(2000);

      // 다시 시도 버튼 클릭 시도
      try {
        const retryButton = await this.page.waitForSelector('button:has-text("다시 시도")', {
          timeout: 3000,
          visible: true
        });
        if (retryButton) {
          console.log("다시 시도 버튼을 찾았습니다. 클릭합니다.");
          await retryButton.click();
          await this.sleep(2000);
        }
      } catch (error) {
        console.log("다시 시도 버튼이 없습니다. 계속 진행합니다.");
      }

      // 이메일 입력 필드 감지
      console.log("이메일 입력 필드 감지 시도...");
      try {
        const emailInput = await this.page.waitForSelector('input[type="email"]', { 
          timeout: 5000,
          visible: true 
        });
        
        if (!emailInput) {
          console.error("이메일 입력 필드를 찾을 수 없습니다.");
          throw new Error("이메일 입력 필드를 찾을 수 없습니다.");
        }
        console.log("이메일 입력 필드 감지 성공");

        // 이메일 입력 (각 문자마다 랜덤 딜레이)
        console.log("이메일 입력 시작:", this.credentials.email);
        for (const char of this.credentials.email) {
          await emailInput.type(char, { delay: Math.random() * 100 + 50 });
        }
        console.log("이메일 입력 완료");
        await this.sleep(1000);

        // 다음 버튼 클릭
        const nextButton = await this.page.waitForSelector('#identifierNext', { 
          timeout: 5000,
          visible: true 
        });
        
        if (nextButton) {
          await nextButton.click();
        } else {
          throw new Error("다음 버튼을 찾을 수 없습니다.");
        }

        // 비밀번호 입력
        const passwordInput = await this.page.waitForSelector('input[type="password"]', { 
          timeout: 5000,
          visible: true 
        });
        
        if (!passwordInput) {
          throw new Error("비밀번호 입력 필드를 찾을 수 없습니다.");
        }

        // 비밀번호 입력 (각 문자마다 랜덤 딜레이)
        for (const char of this.credentials.password) {
          await passwordInput.type(char, { delay: Math.random() * 100 + 50 });
        }
        await this.sleep(1000);

        // 로그인 버튼 클릭
        const passwordNext = await this.page.waitForSelector('#passwordNext', { 
          timeout: 5000,
          visible: true 
        });
        
        if (passwordNext) {
          await passwordNext.click();
        } else {
          throw new Error("로그인 버튼을 찾을 수 없습니다.");
        }

        // 패스키 설정 화면 처리
        try {
          const laterButton = await this.page.waitForSelector('button:has-text("나중에")', {
            timeout: 5000,
            visible: true
          });
          if (laterButton) {
            console.log("패스키 설정 화면에서 '나중에' 선택");
            await laterButton.click();
            await this.sleep(2000);
          }
        } catch (error) {
          console.log("패스키 설정 화면이 나타나지 않았습니다.");
        }

        // YouTube로 이동 및 로그인 확인
        await this.page.waitForSelector("#avatar-btn", { 
          timeout: 30000,
          visible: true 
        });
        
        await this.sleep(2000);

        console.log("로그인 성공!");
      } catch (error) {
        console.error("로그인 중 오류 발생:", error);
        throw error;
      }
    } catch (error) {
      console.error("로그인 중 오류 발생:", error);
      throw error;
    }
  }

  async searchAndAnalyze(keyword: string) {
    if (!this.page) {
      throw new Error("Browser not initialized");
    }

    try {
      // YouTube 메인으로 이동
      await this.page.goto("https://youtube.com");
      await this.sleep(1000);

      // 검색어 입력
      await this.page.waitForSelector('input[name="search_query"]');
      await this.page.click('input[name="search_query"]');
      await this.sleep(250);

      // 기존 검색어 삭제
      await this.page.keyboard.down("Control");
      await this.page.keyboard.press("A");
      await this.page.keyboard.up("Control");
      await this.page.keyboard.press("Backspace");

      // 새 검색어 입력
      await this.page.type('input[name="search_query"]', keyword, { delay: 100 });
      await this.sleep(250);

      // Enter 키로 검색 실행
      await this.page.keyboard.press("Enter");

      // 검색 결과 로딩 대기
      await this.page.waitForSelector("ytd-video-renderer", { timeout: 10000 });
      await this.sleep(2500);

      // "시청하지 않음" 필터 클릭
      await this.page.evaluate(() => {
        const formattedStrings = document.querySelectorAll("yt-formatted-string");
        const videoFilter = Array.from(formattedStrings).find(
          (el) => el.getAttribute("title") === "시청하지 않음"
        );
        if (videoFilter) {
          (videoFilter as any).click();
        }
      });
      await this.sleep(2000);

      let foundValidVideo = false;
      let scrollAttempts = 0;
      const maxScrollAttempts = 10;

      const videoEvaluate = async () => {
        if (!this.page) throw new Error("Browser not initialized");
        return await this.page.evaluate(() => {
          const items = document.querySelectorAll("ytd-video-renderer");
          return Array.from(items).map((item) => {
            const titleElement = item.querySelector("#video-title");
            const id = item
              .querySelector("#thumbnail")
              ?.getAttribute("href")
              ?.split("v=")[1];

            return {
              id: id || "",
              title: titleElement?.textContent?.trim() || "",
              watched: false,
            };
          });
        });
      };

      while (!foundValidVideo && scrollAttempts < maxScrollAttempts) {
        let videos = await videoEvaluate();
        console.log(`검색된 영상 수: ${videos.length}`);

        for (const video of videos) {
          const isWatched = Array.from(this.watchedVideos.values()).some(
            (watchedVideo) =>
              watchedVideo.title.toLowerCase().includes(video.title.toLowerCase()) ||
              video.title.toLowerCase().includes(watchedVideo.title.toLowerCase())
          );

          if (isWatched) {
            const watchedVideo = Array.from(this.watchedVideos.entries()).find(
              ([_, v]) =>
                v.title.toLowerCase().includes(video.title.toLowerCase()) ||
                video.title.toLowerCase().includes(v.title.toLowerCase())
            );
            if (watchedVideo) {
              const hoursSinceWatched =
                (Date.now() - watchedVideo[1].timestamp) / (1000 * 60 * 60);
              console.log(
                `'${video.title}' 유사 영상 시청 후 ${hoursSinceWatched.toFixed(1)}시간 경과`
              );
            }
            video.watched = true;
            continue;
          }

          await this.sleep(1500);
          console.log(`영상 선택: ${video.title}`);
          foundValidVideo = true;
          await this.playVideo(video);
          return [video];
        }

        if (!foundValidVideo) {
          console.log("적합한 영상을 찾지 못했습니다. 스크롤 다운...");
          await this.page.evaluate(() => {
            window.scrollBy(0, window.innerHeight * 3);
          });
          await this.sleep(2000);
          scrollAttempts++;
        }
      }

      console.log("더 이상 시청할 영상을 찾지 못했습니다.");
      return [];
    } catch (error) {
      console.error('검색 중 오류 발생:', error);
      return [];
    }
  }

  private async playVideo(video: { title: string; id: string }) {
    console.log(`재생 시작: ${video.title} (ID: ${video.id})`);

    await this.page?.evaluate((title) => {
      const videoElements = Array.from(
        document.querySelectorAll("ytd-video-renderer")
      );
      const targetVideo = videoElements.find(
        (el) => el.querySelector("#video-title")?.textContent?.trim() === title
      );
      const thumbnailLink = targetVideo?.querySelector("#thumbnail");
      if (thumbnailLink) {
        (thumbnailLink as any).click();
      }
    }, video.title);

    await this.sleep(2500);

    // 광고 스킵 처리
    try {
      await this.page?.waitForSelector(".ytp-ad-skip-button", {
        timeout: 6000,
      });
      await this.page?.click(".ytp-ad-skip-button");
    } catch (e) {
      // 광고가 없거나 스킵할 수 없는 경우 무시
    }

    // 영상 길이 확인 및 시청
    const watchDuration =
      (await this.page?.evaluate(() => {
        const video = document.querySelector("video");
        if (video) {
          return Math.min(video.duration * 1000, 240000);
        }
        return 30000;
      })) || 30000;

    console.log(`영상 시청 시간: ${Math.round(watchDuration / 1000)}초`);
    await this.sleep(watchDuration);

    // 시청 기록에 타임스탬프와 함께 저장
    this.watchedVideos.set(video.id, {
      title: video.title,
      timestamp: Date.now(),
    });
    console.log(`재생 완료: ${video.title} (ID: ${video.id})`);
  }

  async close() {
    // API 클라이언트 정리
    this.browser = null;
    this.page = null;
  }

  private async sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}