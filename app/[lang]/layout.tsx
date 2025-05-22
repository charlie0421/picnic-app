'use client';

import {ReactNode, useEffect} from 'react';
import {Inter} from 'next/font/google';
import './globals.css';
import './layout.css';

// 기존 legacy 프로바이더 (더 이상 사용하지 않음)
// import {SupabaseProvider} from '@/components/providers/SupabaseProvider';
// import {AuthProvider} from '@/contexts/AuthContext';

// 새로운 프로바이더 import
import { SupabaseProvider } from '@/components/providers/SupabaseProvider';
import { AuthProvider } from '@/lib/supabase/auth-provider';

import {NavigationProvider} from '@/contexts/NavigationContext';
import {usePathname} from 'next/navigation';
import {useLanguageStore} from '@/stores/languageStore';
import {Analytics} from '@vercel/analytics/react';

const inter = Inter({ subsets: ['latin'] });

export default function LangLayout({
  children,
}: {
  children: ReactNode;
}) {
  const { loadTranslations } = useLanguageStore();
  const pathname = usePathname();

  useEffect(() => {
    // URL에서 언어 파라미터 가져오기
    const pathSegments = pathname.split('/');
    const lang = pathSegments[1];

    if (lang) {
      loadTranslations(lang);
    }
    if (process.env.NODE_ENV === 'production') {
      // injectSpeedInsights();
    }
  }, [pathname, loadTranslations]);

  useEffect(() => {
      // URL에서 언어 파라미터 가져오기
      const pathSegments = pathname.split('/');
      const lang = pathSegments[1];

      if (lang) {
          loadTranslations(lang);
      }
      if (process.env.NODE_ENV === 'production') {
          // injectSpeedInsights();
      }
  }, [pathname, loadTranslations]);

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
        <NavigationProvider>
          <div className={`layout-container ${inter.className}`}>
            <div className="main-content">
              {children}
            </div>
            {process.env.NODE_ENV === 'production' && <Analytics />}
          </div>
        </NavigationProvider>
      </AuthProvider>
    </SupabaseProvider>
  );
}
