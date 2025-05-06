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
  ],
  
  // CORS 관련 헤더 설정
  async headers() {
    return [
      {
        // 모든 API 경로에 적용
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS,PATCH,DELETE,POST,PUT' },
          { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version' },
        ]
      }
    ]
  }
};

module.exports = nextConfig;
