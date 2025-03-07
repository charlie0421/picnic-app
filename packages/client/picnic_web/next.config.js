/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: 'out',
  images: {
    unoptimized: true,
  },
  // basePath: '', // 필요한 경우 기본 경로 설정
  // trailingSlash: true, // 필요한 경우 URL 끝에 슬래시 추가
};

module.exports = nextConfig;
