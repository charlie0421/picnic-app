/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ['@refinedev/antd'],
  output: 'standalone',
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
};

export default nextConfig;
