'use client';

import React, { useEffect } from 'react';
import { AuthProvider } from '@/contexts/AuthContext';
import Footer from '@/components/layouts/Footer';
import { logEnvironmentInfo } from '@/utils/api/debug';

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  useEffect(() => {
    // 환경 정보 로깅
    if (typeof window !== 'undefined') {
      // 개발 환경 또는 ngrok 환경에서만 디버깅 활성화
      const isNgrok = window.location.hostname.includes('ngrok');
      const isDev = process.env.NODE_ENV === 'development';
      
      if (isNgrok || isDev) {
        // 비동기로 디버깅 모듈 로드 (프로덕션 번들에 포함되지 않도록)
        import('@/utils/api/debug').then(({ enableDebugging }) => {
          enableDebugging();
        });
      }
      
      // 기본 환경 정보는 항상 로깅
      logEnvironmentInfo();
    }
  }, []);

  return (
    <AuthProvider>
      <div className='min-h-screen flex flex-col'>
        <main className='flex-grow'>
          {children}
        </main>
        <Footer />
      </div>
    </AuthProvider>
  );
} 