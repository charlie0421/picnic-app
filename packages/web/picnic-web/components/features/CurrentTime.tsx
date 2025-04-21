'use client';

import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { ko, ja, zhCN, enUS } from 'date-fns/locale';
import { useLanguageStore } from '@/stores/languageStore';

const localeMap = {
  ko,
  ja,
  zh: zhCN,
  en: enUS,
};

const CurrentTime: React.FC = () => {
  const [mounted, setMounted] = useState(false);
  const [currentTime, setCurrentTime] = useState<string>('');
  const { currentLang } = useLanguageStore();

  useEffect(() => {
    setMounted(true);
    const updateTime = () => {
      const now = new Date();
      const locale = localeMap[currentLang as keyof typeof localeMap] || enUS;
      const formattedTime = format(now, 'yyyy.MM.dd (EEE) HH:mm:ss', { locale });
      setCurrentTime(formattedTime);
    };

    updateTime();
    const timer = setInterval(updateTime, 1000);

    return () => clearInterval(timer);
  }, [currentLang]);

  if (!mounted) {
    return null;
  }

  return (
    <span className="font-mono min-w-[180px] inline-block text-center">
      {currentTime}
    </span>
  );
};

export default CurrentTime; 