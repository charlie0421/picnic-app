// sentry 설정 래퍼 추가
const { withSentryConfig } = require('@sentry/nextjs');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  turbopack: {
    resolveAlias: {
      // 필요한 별칭 해결
    }
  },
  experimental: {
    // 다른 experimental 설정을 추가할 수 있습니다.
  },
  images: {
    unoptimized: true,
    remotePatterns: [
      { protocol: 'https', hostname: 'xtijtefcycoeqludlngc.supabase.co' },
      { protocol: 'https', hostname: 'api.picnic.fan' },
      { protocol: 'https', hostname: 'cdn.picnic.fan' },
      { protocol: 'https', hostname: 'picnic-fan.s3.ap-northeast-2.amazonaws.com' },
      { protocol: 'https', hostname: 'img.youtube.com' }
    ],
  },
  allowedDevOrigins: [
    'ngrok-free.app',
    '.ngrok-free.app'
  ],
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS,PATCH,DELETE,POST,PUT' },
          { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, apikey, Authorization' },
        ]
      },
      {
        source: '/supabase-proxy/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS,PATCH,DELETE,POST,PUT' },
          { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization, apikey' },
        ]
      },
      {
        source: '/:lang/supabase-proxy/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS,PATCH,DELETE,POST,PUT' },
          { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization, apikey' },
        ]
      }
    ];
  },
  async rewrites() {
    return [
      {
        source: '/supabase-proxy/:path*',
        destination: 'https://xtijtefcycoeqludlngc.supabase.co/:path*'
      },
      {
        source: '/:lang/supabase-proxy/:path*',
        destination: 'https://xtijtefcycoeqludlngc.supabase.co/:path*'
      }
    ];
  }
};

const sentryWebpackPluginOptions = {
  silent: true, // 로그 비활성화
  // 필요한 경우 authToken, org, project 등 추가 설정
};

module.exports = withSentryConfig(nextConfig, sentryWebpackPluginOptions);