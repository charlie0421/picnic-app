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

interface CurrentTimeProps {
  initialTime?: string;
}

const CurrentTime: React.FC<CurrentTimeProps> = ({ initialTime = new Date().toISOString() }) => {
  const [mounted, setMounted] = useState(false);
  const [currentTime, setCurrentTime] = useState<string>('');
  const { currentLanguage } = useLanguageStore();

  // 초기 시간 설정
  useEffect(() => {
    const initialDate = new Date(initialTime);
    const locale = localeMap[currentLanguage as keyof typeof localeMap] || enUS;
    const formattedTime = format(initialDate, 'yyyy.MM.dd (EEE) HH:mm:ss', { locale });
    setCurrentTime(formattedTime);
    setMounted(true);
  }, [initialTime, currentLanguage]);

  // 시간 업데이트
  useEffect(() => {
    if (!mounted) return;

    const updateTime = () => {
      const now = new Date();
      const locale = localeMap[currentLanguage as keyof typeof localeMap] || enUS;
      const formattedTime = format(now, 'yyyy.MM.dd (EEE) HH:mm:ss', { locale });
      setCurrentTime(formattedTime);
    };

    updateTime();
    const timer = setInterval(updateTime, 1000);

    return () => clearInterval(timer);
  }, [mounted, currentLanguage]);

  return (
    <div className="flex items-center">
      <div className="px-3 py-1.5">
        <span className="font-mono text-gray-700 font-medium text-xs sm:text-sm">
          {currentTime}
        </span>
      </div>
    </div>
  );
};

export default CurrentTime; 