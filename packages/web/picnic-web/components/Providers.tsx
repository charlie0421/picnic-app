'use client';

import React, { useEffect } from 'react';
import { NavigationProvider } from '../contexts/NavigationContext';
import { AuthProvider } from '../contexts/AuthContext';
import Portal from './features/Portal';
import { useLanguageStore } from '@/stores/languageStore';

export default function Providers({ children }: { children: React.ReactNode }) {
  const { loadTranslations } = useLanguageStore();

  useEffect(() => {
    loadTranslations();
  }, [loadTranslations]);

  return (
    <AuthProvider>
      <NavigationProvider>
        <Portal>{children}</Portal>
      </NavigationProvider>
    </AuthProvider>
  );
} 