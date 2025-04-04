'use client';

import React from 'react';
import { LanguageType } from './MultiLanguageInput';

interface MultiLanguageDisplayProps {
  value: Record<LanguageType, string> | undefined;
  showFlags?: boolean;
}

export const MultiLanguageDisplay: React.FC<MultiLanguageDisplayProps> = ({
  value,
  showFlags = true,
}) => {
  if (!value) return '-';

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
        wordBreak: 'break-word',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        {showFlags && (
          <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇰🇷</span>
        )}
        <span>{value.ko || '-'}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        {showFlags && (
          <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇺🇸</span>
        )}
        <span>{value.en || '-'}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        {showFlags && (
          <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇯🇵</span>
        )}
        <span>{value.ja || '-'}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        {showFlags && (
          <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇨🇳</span>
        )}
        <span>{value.zh || '-'}</span>
      </div>
    </div>
  );
};

export default MultiLanguageDisplay;
