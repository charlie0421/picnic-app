import { Inter } from 'next/font/google';
import './globals.css';
import { metadata } from './metadata';

const inter = Inter({ subsets: ['latin'] });

export { metadata };

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang='ko'>
      <head>
        <link rel='manifest' href='/manifest.json' />
        <meta name='msapplication-TileColor' content='#4F46E5' />
        <meta name='theme-color' content='#ffffff' />
      </head>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
