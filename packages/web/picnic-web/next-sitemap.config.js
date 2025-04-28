/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: 'https://www.picnic.fan', // 실제 사이트 URL로 변경
  generateRobotsTxt: true,
  changefreq: 'daily',
  priority: 0.7,
  sitemapSize: 5000,
  exclude: ['/admin/*', '/private/*'],
  robotsTxtOptions: {
    additionalSitemaps: [
      // 동적으로 생성된 추가 사이트맵이 필요한 경우 여기에 추가
    ],
    policies: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/admin', '/private'],
      },
    ],
  },
};
