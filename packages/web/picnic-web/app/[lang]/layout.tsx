import { ReactNode } from 'react';
import { Inter } from 'next/font/google';
import './globals.css';
import './layout.css';
import { SUPPORTED_LANGUAGES } from '@/config/settings';
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
      <div className="main-content">
        {children}
      </div>
    </div>
  );
}
