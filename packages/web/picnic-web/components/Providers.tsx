'use client';

import React, { useEffect } from 'react';
import { NavigationProvider } from '../contexts/NavigationContext';
import { AuthProvider } from '../contexts/AuthContext';
import PortalLayout from './features/PortalLayout';
import { useLanguageStore } from '@/stores/languageStore';
import TranslationProvider from './providers/TranslationProvider';

export default function Providers({ children }: { children: React.ReactNode }) {
  const { currentLanguage } = useLanguageStore();

  return (
    <AuthProvider>
      <NavigationProvider>
        <TranslationProvider
          fallback={
            <div className='relative'>
              <PortalLayout>{children}</PortalLayout>
            </div>
          }
        >
          <div className='relative'>
            <PortalLayout>{children}</PortalLayout>
          </div>
        </TranslationProvider>
      </NavigationProvider>
    </AuthProvider>
  );
}
