import {ReactNode} from 'react';
import {Inter} from 'next/font/google';
import './globals.css';
import './layout.css';
import ClientLayout from './ClientLayout';
import { Metadata } from 'next';

const inter = Inter({ subsets: ['latin'] });

// 동적 메타데이터 생성
export async function generateMetadata({
  params
}: {
  params: { lang: string }
}): Promise<Metadata> {
  return {
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
}

export default function RootLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: { lang: string };
}) {
  // 서버 컴포넌트에서 params 사용
  const lang = params.lang || 'ko';
  
  return (
    <html lang={lang}>
      <body className={inter.className}>
        <ClientLayout initialLanguage={lang}>
          {children}
        </ClientLayout>
      </body>
    </html>
  );
}
