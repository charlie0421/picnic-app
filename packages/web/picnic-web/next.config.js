/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['cdn.picnic.fan', 'img.youtube.com'],
  },
};

module.exports = nextConfig;
