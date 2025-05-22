import { Metadata } from 'next';

// 기본 메타데이터 정의
export const metadata: Metadata = {
  title: {
    default: 'Picnic',
    template: '%s | Picnic',
  },
  description: 'Picnic - 투표 및 미디어 플랫폼',
  openGraph: {
    title: 'Picnic',
    description: 'Picnic - 투표 및 미디어 플랫폼',
    siteName: 'Picnic',
  },
};
