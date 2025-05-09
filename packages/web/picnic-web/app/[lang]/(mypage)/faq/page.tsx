'use client';

import React, {useEffect, useState} from 'react';
import {supabase} from '@/utils/supabase-client';
import {useParams} from 'next/navigation';
import {ChevronDownIcon} from '@heroicons/react/24/outline';

interface MultilingualText {
  en?: string;
  ko?: string;
  ja?: string;
  zh?: string;
  id?: string;
}

interface FAQ {
  id: number;
  question: MultilingualText;
  answer: MultilingualText;
  category: string | null;
  orderNumber: number | null;
  status: string | null;
}

const FAQPage = () => {
  const [faqs, setFaqs] = useState<FAQ[]>([]);
  const [loading, setLoading] = useState(true);
  const [openFaqId, setOpenFaqId] = useState<number | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const params = useParams();
  const currentLang = (params?.lang as string) || 'ko';

  useEffect(() => {
    const fetchFaqs = async () => {
      try {
        const { data, error } = await supabase
          .from('faqs')
          .select('*')
          .order('order_number', { ascending: true });

        if (error) throw error;
        setFaqs(data || []);
      } catch (error) {
        console.error('FAQ를 불러오는 중 오류가 발생했습니다:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchFaqs();
  }, []);

  const getLocalizedText = (text: MultilingualText): string => {
    if (typeof text === 'string') return text;
    return text[currentLang as keyof MultilingualText] || text.ko || text.en || '';
  };

  const toggleFaq = (id: number) => {
    setOpenFaqId(openFaqId === id ? null : id);
  };

  // 카테고리 목록 추출
  const categories = ['all', ...Array.from(new Set(faqs.map(faq => faq.category).filter(Boolean) as string[]))];

  // 선택된 카테고리에 따른 FAQ 필터링
  const filteredFaqs = selectedCategory === 'all'
    ? faqs
    : faqs.filter(faq => faq.category === selectedCategory);

  if (loading) {
    return (
      <div className="min-h-screen flex justify-center items-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h1 className="text-2xl font-bold mb-6 text-gray-900">자주 묻는 질문</h1>

        {/* 카테고리 선택 */}
        <div className="mb-8">
          <div className="flex flex-wrap gap-4">
            {categories.map((category) => (
              <label
                key={category}
                className="inline-flex items-center cursor-pointer"
              >
                <input
                  type="radio"
                  name="category"
                  value={category}
                  checked={selectedCategory === category}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="hidden"
                />
                <span
                  className={`px-4 py-2 rounded-full text-sm font-medium transition-colors
                    ${selectedCategory === category
                      ? 'bg-primary-100 text-primary-800'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                >
                  {category === 'all' ? '전체' : category}
                </span>
              </label>
            ))}
          </div>
        </div>

        <div className="space-y-4">
          {filteredFaqs.length === 0 ? (
            <p className="text-gray-600">해당 카테고리의 FAQ가 없습니다.</p>
          ) : (
            <div className="divide-y divide-gray-200">
              {filteredFaqs.map((faq) => (
                <div key={faq.id} className="py-4">
                  <button
                    onClick={() => toggleFaq(faq.id)}
                    className="w-full flex items-center justify-between text-left"
                  >
                    <div className="flex items-center space-x-2">
                      <span className="text-lg font-semibold text-gray-900">
                        {getLocalizedText(faq.question)}
                      </span>
                    </div>
                    <ChevronDownIcon
                      className={`w-5 h-5 text-gray-500 transition-transform duration-200 ${
                        openFaqId === faq.id ? 'transform rotate-180' : ''
                      }`}
                    />
                  </button>
                  {openFaqId === faq.id && (
                    <div className="mt-4 pl-2 text-gray-600 whitespace-pre-wrap">
                      {getLocalizedText(faq.answer)}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default FAQPage;
