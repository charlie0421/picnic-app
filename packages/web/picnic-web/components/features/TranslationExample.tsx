'use client';

import React, {useEffect, useState} from 'react';
import {useLanguageStore} from '@/stores/languageStore';

const TranslationExample: React.FC = () => {
  const { t } = useLanguageStore();
  const [greeting, setGreeting] = useState('');
  const [welcome, setWelcome] = useState('');

  useEffect(() => {
    setGreeting(t('common_greeting'));
    setWelcome(t('common_welcome'));
  }, [t]);

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-4">{greeting}</h2>
      <p className="text-gray-600">{welcome}</p>
    </div>
  );
};

export default TranslationExample;
