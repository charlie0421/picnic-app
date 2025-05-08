'use client';

import React, { useEffect, useState } from 'react';
import { supabase } from '@/utils/supabase-client';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';

interface MultilingualText {
  en?: string;
  ko?: string;
  ja?: string;
  zh?: string;
  id?: string;
}

interface Notice {
  id: number;
  title: MultilingualText;
  content: MultilingualText;
  createdAt: string | null;
  isPinned: boolean | null;
  status: string | null;
}

const NoticePage = () => {
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);
  const params = useParams();
  const currentLang = (params?.lang as string) || 'ko';
  const router = useRouter();

  useEffect(() => {
    const fetchNotices = async () => {
      try {
        const { data, error } = await supabase
          .from('notices')
          .select('*')
          .order('is_pinned', { ascending: false })
          .order('created_at', { ascending: false });

        if (error) throw error;
        setNotices(data || []);
      } catch (error) {
        console.error('공지사항을 불러오는 중 오류가 발생했습니다:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchNotices();
  }, []);

  const getLocalizedText = (text: MultilingualText): string => {
    if (typeof text === 'string') return text;
    return text[currentLang as keyof MultilingualText] || text.ko || text.en || '';
  };

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
        <h1 className="text-2xl font-bold mb-6 text-gray-900">공지사항</h1>
        <div className="space-y-4">
          {notices.length === 0 ? (
            <p className="text-gray-600">등록된 공지사항이 없습니다.</p>
          ) : (
            <div className="divide-y divide-gray-200">
              {notices.map((notice) => (
                <Link 
                  href={`/notice/${notice.id}`} 
                  key={notice.id}
                  className="block hover:bg-gray-50 transition-colors"
                >
                  <div className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        {notice.isPinned && (
                          <span className="bg-primary-100 text-primary-800 text-xs font-medium px-2.5 py-0.5 rounded">
                            공지
                          </span>
                        )}
                        <h2 className="text-lg font-semibold text-gray-900">{getLocalizedText(notice.title)}</h2>
                      </div>
                      <div className="flex flex-col items-end">
                        <span className="text-sm text-gray-600">
                          {notice.createdAt && format(new Date(notice.createdAt), 'yyyy년 MM월 dd일', { locale: ko })}
                        </span>
                        <span className="text-xs text-gray-500">
                          {notice.createdAt && format(new Date(notice.createdAt), 'HH:mm', { locale: ko })}
                        </span>
                      </div>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default NoticePage;