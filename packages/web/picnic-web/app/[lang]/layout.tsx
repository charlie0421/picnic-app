import { ReactNode } from 'react';
import { Inter } from 'next/font/google';
import './globals.css';
import './layout.css';
import { SUPPORTED_LANGUAGES } from '@/config/settings';
import Root from '../root';

const inter = Inter({ subsets: ['latin'] });


export function generateStaticParams() {
  return SUPPORTED_LANGUAGES.map((lang) => ({ lang }));
}

export default function LangLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <div className={`layout-container ${inter.className}`}>
      <Root />
      <div className="main-content">
        {children}
      </div>
    </div>
  );
}
