'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';

const languages = [
  { code: 'ko', name: '한국어' },
  { code: 'en', name: 'English' },
  { code: 'ja', name: '日本語' },
  { code: 'zh', name: '中文' },
  { code: 'id', name: 'Bahasa Indonesia' }
];

const LanguageSelector: React.FC = () => {
  const { currentLang, changeLanguage } = useLanguage();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  
  const currentLanguage = languages.find(lang => lang.code === currentLang);
  const otherLanguages = languages.filter(lang => lang.code !== currentLang);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  return (
    <div 
      ref={dropdownRef}
      style={{ 
        position: 'relative', 
        display: 'inline-block',
        width: '170px'
      }}
    >
      <button
        type="button"
        onClick={toggleDropdown}
        style={{
          padding: '8px 12px',
          border: '1px solid #e5e7eb',
          borderRadius: '6px',
          backgroundColor: 'white',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          width: '170px',
          justifyContent: 'space-between',
          color: '#374151',
          position: 'relative',
          fontSize: '13px'
        }}
      >
        <span>{currentLanguage?.name || 'Language'}</span>
        <span style={{ 
          transform: isOpen ? 'rotate(180deg)' : 'none', 
          transition: 'transform 0.2s',
          fontSize: '12px'
        }}>
          ▼
        </span>
      </button>

      <div
        style={{
          visibility: isOpen ? 'visible' : 'hidden',
          opacity: isOpen ? 1 : 0,
          position: 'fixed',
          top: dropdownRef.current ? dropdownRef.current.getBoundingClientRect().bottom + 4 : 0,
          left: dropdownRef.current ? dropdownRef.current.getBoundingClientRect().left : 0,
          backgroundColor: 'white',
          border: '1px solid #e5e7eb',
          borderRadius: '6px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          width: '170px',
          maxHeight: '300px',
          overflowY: 'auto',
          transition: 'opacity 0.2s ease-in-out',
          zIndex: 9999,
          fontSize: '14px'
        }}
      >
        {otherLanguages.map((language) => (
          <button
            key={language.code}
            type="button"
            onClick={() => {
              changeLanguage(language.code);
              setIsOpen(false);
            }}
            style={{
              display: 'block',
              width: '100%',
              padding: '8px 12px',
              textAlign: 'left',
              border: 'none',
              backgroundColor: 'white',
              color: '#374151',
              cursor: 'pointer',
              transition: 'background-color 0.2s',
              borderBottom: '1px solid #f3f4f6'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = '#f3f4f6';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = 'white';
            }}
          >
            {language.name}
          </button>
        ))}
      </div>
    </div>
  );
};

export default LanguageSelector; 