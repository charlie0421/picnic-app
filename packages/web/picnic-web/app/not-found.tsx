'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useLanguageStore } from '@/stores/languageStore';
import { useEffect, useState } from 'react';

export default function NotFound() {
  const { t } = useLanguageStore();
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  if (!isClient) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-2xl w-full mx-4">
        <div className="bg-white rounded-2xl shadow-sm p-8 md:p-12">
          <div className="text-center">
            <div className="mb-8">
              <Image
                src="/images/logo.png"
                alt="Picnic Logo"
                width={120}
                height={120}
                className="mx-auto"
              />
            </div>
            
            <div className="relative inline-block mb-6">
              <h1 className="text-8xl font-bold text-purple-600">404</h1>
              <div className="absolute -top-2 -right-2 w-8 h-8 bg-yellow-400 rounded-full flex items-center justify-center">
                <span className="text-sm font-bold text-white">!</span>
              </div>
            </div>

            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              {t('notFound.title')}
            </h2>
            <p className="text-gray-600 mb-8 max-w-md mx-auto whitespace-pre-line">
              {t('notFound.description')}
            </p>

            <div className="flex flex-col sm:flex-row justify-center gap-4">
              <Link 
                href="/"
                className="inline-flex items-center justify-center px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors duration-200 shadow-sm hover:shadow-md"
              >
                {t('notFound.homeButton')}
              </Link>
              <Link 
                href="/contact"
                className="inline-flex items-center justify-center px-6 py-3 bg-white text-purple-600 border border-purple-200 rounded-lg hover:bg-purple-50 transition-colors duration-200 shadow-sm hover:shadow-md"
              >
                {t('notFound.contactButton')}
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 