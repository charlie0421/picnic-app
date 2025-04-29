'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { useRouter, usePathname } from 'next/navigation';

const languages = [
  { code: 'ko', name: '한국어' },
  { code: 'en', name: 'English' },
  { code: 'ja', name: '日本語' },
  { code: 'zh', name: '中文' },
  { code: 'id', name: 'Bahasa Indonesia' },
];

const LanguageSelector: React.FC = () => {
  const { currentLanguage, setLanguage, syncLanguageWithPath } = useLanguageStore();
  const [isOpen, setIsOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const router = useRouter();
  const pathname = usePathname();

  // 마운트 시와 라우트 변경 시 언어 동기화
  useEffect(() => {
    setMounted(true);
    
    // URL이 변경될 때마다 현재 언어 상태를 URL과 동기화
    syncLanguageWithPath();
    
    return () => setMounted(false);
  }, [pathname, syncLanguageWithPath]);

  const currentLanguageObj = languages.find((lang) => lang.code === currentLanguage);

  useEffect(() => {
    if (!mounted) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [mounted]);

  const toggleDropdown = () => {
    if (!mounted) return;
    setIsOpen(!isOpen);
  };

  const handleLanguageChange = async (lang: string) => {
    if (lang === currentLanguage) return;
    
    // 현재 경로에서 언어 코드 부분만 교체
    let newPath = pathname;
    const pathSegments = pathname.split('/');
    
    // 첫 번째 세그먼트가 언어 코드인 경우 교체
    if (pathSegments.length > 1 && languages.some(l => l.code === pathSegments[1])) {
      pathSegments[1] = lang;
      newPath = pathSegments.join('/');
    } else {
      // 언어 코드가 없는 경우 추가
      newPath = `/${lang}${pathname}`;
    }
    
    // 상태 변경 및 페이지 이동
    await setLanguage(lang as any);
    router.push(newPath);
    setIsOpen(false);
  };

  // 서버 사이드에서는 빈 div를 렌더링
  if (!mounted) {
    return (
      <div
        style={{
          width: '170px',
          height: '36px',
        }}
      />
    );
  }

  return (
    <div
      ref={dropdownRef}
      style={{
        position: 'relative',
        display: 'inline-block',
        width: '170px',
      }}
    >
      <button
        type='button'
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
          fontSize: '13px',
        }}
      >
        <span>{currentLanguageObj?.name || 'Language'}</span>
        <span
          style={{
            transform: isOpen ? 'rotate(180deg)' : 'none',
            transition: 'transform 0.2s',
            fontSize: '12px',
          }}
        >
          ▼
        </span>
      </button>

      <div
        style={{
          visibility: isOpen ? 'visible' : 'hidden',
          opacity: isOpen ? 1 : 0,
          position: 'fixed',
          top: dropdownRef.current
            ? dropdownRef.current.getBoundingClientRect().bottom + 4
            : 0,
          left: dropdownRef.current
            ? dropdownRef.current.getBoundingClientRect().left
            : 0,
          backgroundColor: 'white',
          border: '1px solid #e5e7eb',
          borderRadius: '6px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          width: '170px',
          maxHeight: '300px',
          overflowY: 'auto',
          transition: 'opacity 0.2s ease-in-out',
          zIndex: 9999,
          fontSize: '14px',
        }}
      >
        {languages.map((language) => {
          const isCurrentLanguage = language.code === currentLanguage;
          return (
            <button
              key={language.code}
              type='button'
              onClick={() => handleLanguageChange(language.code)}
              disabled={isCurrentLanguage}
              style={{
                display: 'block',
                width: '100%',
                padding: '8px 12px',
                textAlign: 'left',
                border: 'none',
                backgroundColor: isCurrentLanguage ? '#f0f0f0' : 'white',
                color: isCurrentLanguage ? '#9ca3af' : '#374151',
                cursor: isCurrentLanguage ? 'default' : 'pointer',
                transition: 'background-color 0.2s',
                borderBottom: '1px solid #f3f4f6',
                fontWeight: isCurrentLanguage ? 'bold' : 'normal',
              }}
              onMouseEnter={(e) => {
                if (!isCurrentLanguage && mounted) {
                  e.currentTarget.style.backgroundColor = '#f3f4f6';
                }
              }}
              onMouseLeave={(e) => {
                if (mounted) {
                  e.currentTarget.style.backgroundColor = isCurrentLanguage
                    ? '#f0f0f0'
                    : 'white';
                }
              }}
            >
              {language.name}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default LanguageSelector;
