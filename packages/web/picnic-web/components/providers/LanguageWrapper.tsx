'use client';

import { useEffect } from 'react';
import { useLanguageStore } from '@/stores/languageStore';

export default function LanguageWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  const { loadTranslations } = useLanguageStore();

  useEffect(() => {
    loadTranslations();
  }, [loadTranslations]);

  return <>{children}</>;
} 