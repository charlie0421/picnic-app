/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: [
      'xtijtefcycoeqludlngc.supabase.co',
      'api.picnic.fan',
      'cdn.picnic.fan',
      'picnic-fan.s3.ap-northeast-2.amazonaws.com',
      'img.youtube.com'
    ],
  },
  logging: {
    fetches: {
      fullUrl: true
    }
  }
};

module.exports = nextConfig;
