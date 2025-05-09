import React, {useEffect, useState} from 'react';
import {usePathname, useRouter} from 'next/navigation';
import {useLanguageStore} from '@/stores/languageStore';
import {type Language, settings} from '@/config/settings';

const LanguageSelector: React.FC = () => {
  const { currentLanguage, setLanguage } = useLanguageStore();
  const router = useRouter();
  const pathname = usePathname();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleLanguageChange = (lang: Language) => {
    if (lang !== currentLanguage) {
      setLanguage(lang);
      // URL의 언어 코드 변경
      const newPath = pathname.replace(/^\/[a-z]{2}/, `/${lang}`);
      router.push(newPath);
    }
  };

  if (!mounted) return null;

  return (
    <div className="flex items-center space-x-2">
      {settings.languages.supported.map((lang) => (
        <button
          key={lang}
          onClick={() => handleLanguageChange(lang)}
          className={`px-2 py-1 text-sm rounded ${
            currentLanguage === lang
              ? 'bg-primary text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          }`}
        >
          {lang.toUpperCase()}
        </button>
      ))}
    </div>
  );
};

export default LanguageSelector;
