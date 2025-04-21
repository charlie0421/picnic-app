'use client';

import React, { useEffect } from 'react';
import { Inter } from 'next/font/google';
import './globals.css';
import { AuthProvider } from '../contexts/AuthContext';
import { NavigationProvider } from '../contexts/NavigationContext';
import Portal from '@/components/features/Portal';
import { redirect } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';

const inter = Inter({ subsets: ['latin'] });

const RootLayout = ({ children }: { children: React.ReactNode }) => {
  const { loadTranslations } = useLanguageStore();

  useEffect(() => {
    // 초기 번역 데이터 로드
    loadTranslations();
  }, [loadTranslations]);

  // 홈 경로로 접근할 경우 투표 홈으로 리디렉션
  if (typeof window !== 'undefined' && window.location.pathname === '/') {
    redirect('/vote');
  }

  return (
    <html lang="ko">
      <body className={inter.className}>
        <AuthProvider>
          <NavigationProvider>
            <Portal>{children}</Portal>
          </NavigationProvider>
        </AuthProvider>
      </body>
    </html>
  );
};

export default RootLayout;
