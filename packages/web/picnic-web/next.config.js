/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'xtijtefcycoeqludlngc.supabase.co',
      },
      {
        protocol: 'https',
        hostname: 'api.picnic.fan',
      },
      {
        protocol: 'https',
        hostname: 'cdn.picnic.fan',
      },
      {
        protocol: 'https',
        hostname: 'picnic-fan.s3.ap-northeast-2.amazonaws.com',
      },
      {
        protocol: 'https',
        hostname: 'img.youtube.com',
      }
    ],
  },
  // 개발 환경에서 ngrok과 같은 외부 도메인 허용
  allowedDevOrigins: [
    'ngrok-free.app',
    '.ngrok-free.app'
  ]
};

module.exports = nextConfig;
