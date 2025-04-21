'use client';

import React, { useState, useEffect } from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { TRANSLATION_KEYS } from '@/constants/translations';

const TranslationExample: React.FC = () => {
  const { t } = useLanguageStore();
  const [greeting, setGreeting] = useState('');
  const [welcome, setWelcome] = useState('');

  useEffect(() => {
    setGreeting(t(TRANSLATION_KEYS.COMMON.GREETING));
    setWelcome(t(TRANSLATION_KEYS.COMMON.WELCOME));
  }, [t]);

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-4">{greeting}</h2>
      <p className="text-gray-600">{welcome}</p>
    </div>
  );
};

export default TranslationExample; 