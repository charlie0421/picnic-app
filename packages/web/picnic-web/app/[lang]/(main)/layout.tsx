'use client';

import React, { useEffect } from 'react';
import { AuthProvider } from '@/contexts/AuthContext';
import Footer from '@/components/layouts/Footer';
import { SupabaseProvider } from '@/components/providers/SupabaseProvider';

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
      
    }
  }, []);

  return (
    <SupabaseProvider>
      <AuthProvider>
        <div className='min-h-screen flex flex-col'>
          <main className='flex-grow'>
            {children}
          </main>
          <Footer />
        </div>
      </AuthProvider>
    </SupabaseProvider>
  );
} 