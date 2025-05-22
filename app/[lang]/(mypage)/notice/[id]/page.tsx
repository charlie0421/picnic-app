'use client';

import React, {useEffect, useState} from 'react';
import {supabase} from '@/utils/supabase-client';
import {format} from 'date-fns';
import {ko} from 'date-fns/locale';
import {useParams, useRouter} from 'next/navigation';
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

const NoticeDetailPage = () => {
  const [notice, setNotice] = useState<Notice | null>(null);
  const [loading, setLoading] = useState(true);
  const params = useParams();
  const currentLang = (params?.lang as string) || 'ko';
  const router = useRouter();
  const noticeId = params?.id;

  useEffect(() => {
    const fetchNotice = async () => {
      try {
        const { data, error } = await supabase
          .from('notices')
          .select('*')
          .eq('id', noticeId)
          .single();

        if (error) throw error;
        setNotice(data);
      } catch (error) {
        console.error('공지사항을 불러오는 중 오류가 발생했습니다:', error);
        router.push('/notice');
      } finally {
        setLoading(false);
      }
    };

    if (noticeId) {
      fetchNotice();
    }
  }, [noticeId, router]);

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

  if (!notice) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <p className="text-gray-600">공지사항을 찾을 수 없습니다.</p>
          <Link href="/notice" className="text-primary-600 hover:underline mt-4 inline-block">
            목록으로 돌아가기
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="mb-6">
          <Link href="/notice" className="text-primary-600 hover:underline">
            ← 목록으로 돌아가기
          </Link>
        </div>

        <div className="border-b pb-4 mb-6">
          <div className="flex items-center space-x-2 mb-2">
            {notice.isPinned && (
              <span className="bg-primary-100 text-primary-800 text-xs font-medium px-2.5 py-0.5 rounded">
                공지
              </span>
            )}
            <h1 className="text-2xl font-bold text-gray-900">{getLocalizedText(notice.title)}</h1>
          </div>
          <span className="text-sm text-gray-500">
            {notice.createdAt && format(new Date(notice.createdAt), 'yyyy년 MM월 dd일', { locale: ko })}
          </span>
        </div>

        <div className="prose max-w-none text-gray-900">
          <p className="whitespace-pre-wrap">{getLocalizedText(notice.content)}</p>
        </div>
      </div>
    </div>
  );
};

export default NoticeDetailPage;
