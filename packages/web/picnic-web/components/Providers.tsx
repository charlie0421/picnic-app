'use client';

import React, { useEffect } from 'react';
import { NavigationProvider } from '../contexts/NavigationContext';
import { AuthProvider } from '../contexts/AuthContext';
import PortalLayout from './features/PortalLayout';
import { useLanguageStore } from '@/stores/languageStore';

export default function Providers({ children }: { children: React.ReactNode }) {
  const { loadTranslations, currentLanguage } = useLanguageStore();

  useEffect(() => {
    loadTranslations(currentLanguage);
  }, [loadTranslations, currentLanguage]);

  return (
    <AuthProvider>
      <NavigationProvider>
        <div className='relative'>
          <PortalLayout>{children}</PortalLayout>
        </div>
      </NavigationProvider>
    </AuthProvider>
  );
}
