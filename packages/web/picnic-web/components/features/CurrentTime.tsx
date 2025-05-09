'use client';

import React, { useState, useEffect, useRef } from 'react';
import { format } from 'date-fns';
import { useLanguageStore } from '@/stores/languageStore';
import { localeMap, getCurrentLocale } from '@/utils/date';
import { enUS } from 'date-fns/locale';

interface CurrentTimeProps {
  initialTime?: string;
}

const CurrentTime: React.FC<CurrentTimeProps> = ({
  initialTime = new Date().toISOString(),
}) => {
  const [mounted, setMounted] = useState(false);
  const [currentTime, setCurrentTime] = useState<string>('');
  const { currentLanguage } = useLanguageStore();
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const prevLanguage = useRef<string>(currentLanguage);

  // 컴포넌트 마운트 시 초기화
  useEffect(() => {
    setMounted(true);

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  // 언어 변경 또는 마운트 시 시간 포맷 업데이트
  useEffect(() => {
    if (!mounted) return;

    // 이전 타이머 정리
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }

    const updateTime = () => {
      const now = new Date();
      const locale = getCurrentLocale(currentLanguage);
      const formattedTime = format(now, 'yyyy.MM.dd (EEE) HH:mm:ss', {
        locale,
      });
      setCurrentTime(formattedTime);
    };

    // 즉시 한 번 업데이트
    updateTime();

    // 정기적인 업데이트 설정
    timerRef.current = setInterval(updateTime, 1000);

    // 언어 변경 기록
    prevLanguage.current = currentLanguage;

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [mounted, currentLanguage]);

  if (!mounted) return null;

  return (
    <div className='flex items-center'>
      <div className='px-3 py-1.5'>
        <span className='font-mono text-gray-700 font-medium text-xs sm:text-sm'>
          {currentTime}
        </span>
      </div>
    </div>
  );
};

export default CurrentTime;
