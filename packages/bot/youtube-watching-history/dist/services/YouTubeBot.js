"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.YouTubeBot = void 0;
const puppeteer_1 = __importDefault(require("puppeteer"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
class YouTubeBot {
    constructor() {
        this.browser = null;
        this.page = null;
        this.credentials = null;
    }
    loadCredentials() {
        try {
            const credentialsPath = path.join(__dirname, '../config/credentials.json');
            const credentialsData = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
            this.credentials = credentialsData.youtube;
        }
        catch (error) {
            throw new Error('Failed to load credentials from file');
        }
    }
    async init() {
        this.browser = await puppeteer_1.default.launch({
            headless: false,
            defaultViewport: null,
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
        }
        catch (error) {
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
                    loadTimes: () => { },
                    csi: () => { },
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
            window.navigator.permissions.query = (parameters) => (parameters.name === 'notifications' ?
                Promise.resolve({
                    state: Notification.permission,
                    name: 'notifications',
                    onchange: null,
                    addEventListener: () => { },
                    removeEventListener: () => { },
                    dispatchEvent: () => true
                }) :
                originalQuery(parameters));
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
        if (!this.page)
            throw new Error("Browser not initialized");
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
            alert("로그인 시작");
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
            console.log("로그인 버튼 클릭 완료");
            await this.sleep(2000);
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
                // 현재 페이지의 HTML 구조 확인
                const pageContent = await this.page.content();
                console.log("현재 페이지 HTML 구조:", pageContent);
                // 이메일 입력 (각 문자마다 랜덤 딜레이)
                console.log("이메일 입력 시작:", this.credentials.email);
                for (const char of this.credentials.email) {
                    await emailInput.type(char, { delay: Math.random() * 100 + 50 });
                }
                console.log("이메일 입력 완료");
                await this.sleep(1000);
            }
            catch (error) {
                console.error("이메일 입력 필드 처리 중 오류 발생:", error);
                throw error;
            }
            // 다음 버튼 클릭
            const nextButton = await this.page.waitForSelector('#identifierNext', {
                timeout: 5000,
                visible: true
            });
            if (nextButton) {
                await nextButton.click();
            }
            else {
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
            }
            else {
                throw new Error("로그인 버튼을 찾을 수 없습니다.");
            }
            // YouTube로 이동 및 로그인 확인
            await this.page.waitForSelector("#avatar-btn", {
                timeout: 30000,
                visible: true
            });
            await this.sleep(2000);
            console.log("로그인 성공!");
        }
        catch (error) {
            console.error("로그인 중 오류 발생:", error);
            throw error;
        }
    }
    async searchAndAnalyze(keyword) {
        if (!this.page) {
            throw new Error("Browser not initialized");
        }
        try {
            // 검색 실행
            await this.page.goto(`https://www.youtube.com/results?search_query=${encodeURIComponent(keyword)}`, { waitUntil: 'networkidle0' });
            await this.sleep(2000);
            const videos = await this.page.evaluate(() => {
                const videoElements = Array.from(document.querySelectorAll('ytd-video-renderer'));
                return videoElements.map(element => {
                    const title = element.querySelector('a[id="video-title"]')?.textContent || '';
                    const videoId = element.querySelector('a[id="video-title"]')?.getAttribute('href')?.split('/').pop() || '';
                    return { title, videoId };
                });
            });
            console.log(`검색된 영상 수: ${videos.length}`);
            // 여기에 영상 분석 로직 추가
            // ...
            return videos;
        }
        catch (error) {
            console.error('검색 중 오류 발생:', error);
            return [];
        }
    }
    async close() {
        // API 클라이언트 정리
        this.browser = null;
        this.page = null;
    }
    async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
exports.YouTubeBot = YouTubeBot;
