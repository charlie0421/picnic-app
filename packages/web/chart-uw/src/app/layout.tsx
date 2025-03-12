import type { Metadata } from 'next';
import localFont from 'next/font/local';
import './globals.css';

const pretandard = localFont({
  src: [
    {
      path: './fonts/Pretendard-Regular.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: './fonts/Pretendard-Bold.woff2',
      weight: '700',
      style: 'normal',
    },
  ],
  variable: '--font-pretandard',
});

export const metadata: Metadata = {
  title: '픽차트',
  icons: {
    icon: '/images/Icon-192.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang='ko'>
      <body className={`${pretandard.variable} antialiased`}>{children}</body>
    </html>
  );
}
