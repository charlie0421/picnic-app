'use client';

import React, { useState, useContext } from 'react';
import { LanguageType } from './MultiLanguageInput';
import { ColorModeContext } from '@/contexts/color-mode';
import { theme } from 'antd';

interface MultiLanguageDisplayProps {
  value: Record<LanguageType, string> | string | undefined;
  showFlags?: boolean;
  languages?: LanguageType[];
  style?: React.CSSProperties;
}

export const MultiLanguageDisplay: React.FC<MultiLanguageDisplayProps> = ({
  value,
  showFlags = true,
  languages,
  style,
}) => {
  const [showTooltip, setShowTooltip] = useState(false);
  
  // 테마 모드 확인
  const { mode } = useContext(ColorModeContext);
  const isDarkMode = mode === 'dark';
  const { token } = theme.useToken();
  
  if (!value) return <span style={{ color: isDarkMode ? '#ffffff' : token.colorText, ...style }}>-</span>;

  // 문자열인 경우 한국어로 처리
  if (typeof value === 'string') {
    return <span style={{ color: isDarkMode ? '#ffffff' : token.colorText, ...style }}>{value}</span>;
  }

  const languagesToDisplay = languages || ['ko', 'en', 'ja', 'zh','id'] as LanguageType[];
  const allLanguages = ['ko', 'en', 'ja', 'zh','id'] as LanguageType[];
  const isFilteredView = languages && languages.length !== allLanguages.length;

  // 언어별 국기 이모지 맵핑
  const flagMap: Record<LanguageType, string> = {
    ko: '🇰🇷',
    en: '🇺🇸',
    ja: '🇯🇵',
    zh: '🇨🇳',
    id: '🇮🇩',
  };

  // 텍스트 스타일 - 다크모드 지원
  const textStyle = {
    color: isDarkMode ? '#ffffff' : token.colorText,
    ...style
  };

  const renderLanguageItem = (lang: LanguageType) => (
    <div key={lang} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
      {showFlags && (
        <span style={{ fontWeight: 'bold', flexShrink: 0 }}>{flagMap[lang]}</span>
      )}
      <span style={textStyle}>{value[lang] || '-'}</span>
    </div>
  );

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
        wordBreak: 'break-word',
        position: 'relative',
        ...style,
      }}
      onMouseEnter={() => isFilteredView && setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
    >
      {languagesToDisplay.map(renderLanguageItem)}
      
      {isFilteredView && showTooltip && (
        <div
          style={{
            position: 'absolute',
            top: '100%',
            left: '0',
            backgroundColor: isDarkMode ? token.colorBgElevated : 'white',
            border: `1px solid ${isDarkMode ? token.colorBorderSecondary : '#eaeaea'}`,
            borderRadius: '4px',
            padding: '8px',
            boxShadow: isDarkMode 
              ? `0 2px 10px rgba(0, 0, 0, 0.3)` 
              : `0 2px 10px rgba(0, 0, 0, 0.1)`,
            zIndex: 1000,
            minWidth: '200px',
          }}
        >
          <div style={{ fontWeight: 'bold', marginBottom: '8px', color: isDarkMode ? '#ffffff' : 'inherit' }}>모든 언어</div>
          {allLanguages.map(renderLanguageItem)}
        </div>
      )}
    </div>
  );
};

export default MultiLanguageDisplay;
