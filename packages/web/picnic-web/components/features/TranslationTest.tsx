'use client';

import React, { useEffect, useState } from 'react';
import { useLanguageStore } from '@/stores/languageStore';

const TranslationTest: React.FC = () => {
  const { t, currentLang, translations } = useLanguageStore();
  const [testResults, setTestResults] = useState<Record<string, string>>({});
  const [systemLang, setSystemLang] = useState<string>('');

  useEffect(() => {
    const getSystemLanguage = () => {
      if (typeof window === 'undefined') return 'ko';
      const lang = navigator.language.split('-')[0];
      return ['ko', 'en', 'ja', 'zh', 'id'].includes(lang) ? lang : 'ko';
    };

    setSystemLang(getSystemLanguage());
  }, []);

  useEffect(() => {
    const testKeys = [
      'nav_vote',
      'nav_picchart',
      'nav_media',
      'nav_store',
      'test_key_1',
      'test_key_2'
    ];

    const results: Record<string, string> = {};
    testKeys.forEach(key => {
      results[key] = t(key);
    });

    setTestResults(results);
  }, [t]);

  return (
    <div className="p-4 border rounded-lg bg-gray-50">
      <h3 className="text-lg font-bold mb-4">번역 테스트</h3>
      <div className="space-y-4">
        <div>
          <strong>시스템 언어:</strong> {systemLang}
        </div>
        <div>
          <strong>현재 언어:</strong> {currentLang}
        </div>
        <div>
          <strong>로드된 번역 수:</strong> {Object.keys(translations).length}
        </div>
        <div>
          <strong>번역 키 목록:</strong>
          <div className="mt-2 space-y-1">
            {Object.entries(testResults).map(([key, value]) => (
              <div key={key} className="flex items-center space-x-2">
                <span className="font-mono text-sm bg-gray-200 px-2 py-1 rounded">{key}</span>
                <span className="text-gray-600">→</span>
                <span className={value === key ? 'text-red-500' : 'text-green-500'}>
                  {value}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default TranslationTest; 