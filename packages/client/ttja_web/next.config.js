/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: 'out',
  images: {
    unoptimized: true,
  },
  // basePath: '', // 필요한 경우 기본 경로 설정
  // trailingSlash: true, // 필요한 경우 URL 끝에 슬래시 추가
  
  // 서버와 클라이언트 코드를 구분하기 위한 웹팩 설정
  webpack: (config, { isServer }) => {
    // 서버 사이드에서 실행될 때 브라우저 전용 모듈을 빈 객체로 대체
    if (isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        // 브라우저 전용 API들을 빈 객체로 대체
        window: false,
        self: false,
        document: false,
      };
    }
    
    return config;
  },
};

module.exports = nextConfig;
