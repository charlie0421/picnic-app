'use client';

import { useContext } from 'react';
import { ColorModeContext } from '@/contexts/color-mode';

interface StatisticsClientProps {
  iframeUrl: string;
}

export default function StatisticsClient({ iframeUrl }: StatisticsClientProps) {
  const { mode } = useContext(ColorModeContext);
  const isDarkMode = mode === 'dark';
  
  // URL에 다크모드 파라미터 추가
  const finalUrl = iframeUrl.replace('theme=neutral', `theme=${isDarkMode ? 'night' : 'light'}`);
  
  return (
    <div>
      <iframe src={finalUrl} width="100%" height="1000px" />
    </div>
  );
} 