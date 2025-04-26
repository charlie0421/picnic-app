'use client';

import { NavigationProvider } from '@/contexts/NavigationContext';
import Portal from '@/components/features/Portal';
import { useLanguageStore } from '@/stores/languageStore';
import { useEffect } from 'react';

export default function MainTemplate({
  children,
}: {
  children: React.ReactNode;
}) {
  const { loadTranslations } = useLanguageStore();

  useEffect(() => {
    loadTranslations();
  }, [loadTranslations]);

  return (
    <NavigationProvider>
      <Portal>{children}</Portal>
    </NavigationProvider>
  );
} 