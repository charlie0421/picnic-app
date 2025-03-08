/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: 'out',
  images: {
    unoptimized: true,
  },
  // basePath: '', // 필요한 경우 기본 경로 설정
  // trailingSlash: true, // 필요한 경우 URL 끝에 슬래시 추가
  
  // 브라우저 전용 코드를 서버에서 실행할 때 발생하는 문제 해결
  webpack: (config, { isServer }) => {
    // 서버 사이드에서 실행될 때 브라우저 전용 모듈을 처리
    if (isServer) {
      // 기존 fallback이 없을 경우 생성
      if (!config.resolve.fallback) {
        config.resolve.fallback = {};
      }
      
      // 브라우저 전용 API 모킹
      Object.assign(config.resolve.fallback, {
        fs: false,
        net: false,
        tls: false,
        child_process: false,
        window: false,
        self: false,
        document: false,
        localStorage: false,
        sessionStorage: false,
        navigator: false,
      });
    }
    
    return config;
  },
};

module.exports = nextConfig;
