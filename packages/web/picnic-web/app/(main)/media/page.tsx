'use client';

import React, { useEffect, useState } from 'react';
import { Media } from '@/types/interfaces';
import { getMedias } from '@/utils/api/queries';
import { getLocalizedString } from '@/utils/api/image';
import Link from 'next/link';
import Image from 'next/image';
import Footer from '@/components/layouts/Footer';
import Menu from '@/components/features/Menu';
import { useLanguageStore } from '@/stores/languageStore';

const MediaPage: React.FC = () => {
  const [medias, setMedias] = useState<Media[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);
  const { currentLang } = useLanguageStore();

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const mediasData = await getMedias();
        console.log('미디어 데이터:', mediasData); // 데이터 구조 확인용 로그
        setMedias(mediasData);
        setIsLoading(false);
      } catch (error) {
        console.error(
          '미디어 데이터를 가져오는 중 오류가 발생했습니다:',
          error,
        );
        setError('미디어 데이터를 불러오는 중 오류가 발생했습니다.');
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const getTitleString = (title: any) => {
    if (!title) return '제목 없음';
    if (typeof title === 'string') return title;
    return getLocalizedString(title) || '제목 없음';
  };

  const renderThumbnail = (media: Media) => {
    console.log('렌더링 중인 미디어:', media); // 디버깅용 로그

    // 유효한 videoId 확인 - 디버깅 메시지 추가
    const hasValidVideoId =
      media.videoId &&
      typeof media.videoId === 'string' &&
      media.videoId.trim() !== '';
    console.log('유효한 videoId:', hasValidVideoId, media.videoId);

    // 썸네일 URL 결정 로직 개선
    let thumbnailUrl = '/images/logo.png'; // 기존에 존재하는 로고 이미지를 기본값으로 사용

    if (media.thumbnailUrl) {
      thumbnailUrl = media.thumbnailUrl;
    } else if (hasValidVideoId) {
      thumbnailUrl = `https://img.youtube.com/vi/${media.videoId}/0.jpg`;
    }

    console.log('사용된 썸네일 URL:', thumbnailUrl); // 디버깅용 로그

    return (
      <div className='relative w-full aspect-video overflow-hidden rounded-lg'>
        <Image
          src={thumbnailUrl}
          alt={getTitleString(media.title)}
          fill
          className='object-cover transition-transform duration-300 hover:scale-105'
          sizes='(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw'
          unoptimized={thumbnailUrl.startsWith('https://img.youtube.com')}
          onError={(e) => {
            // 이미지 로딩에 실패한 경우 기본 이미지로 대체
            console.log('이미지 로딩 실패, 기본 이미지로 대체');
            const target = e.target as HTMLImageElement;
            target.onerror = null; // 무한 루프 방지
            target.src = '/images/logo.png';
          }}
        />
        <div className='absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-300'>
          <div className='bg-white/20 backdrop-blur-sm rounded-full p-4'>
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-12 w-12 text-white drop-shadow-lg'
              fill='none'
              viewBox='0 0 24 24'
              stroke='currentColor'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z'
              />
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
              />
            </svg>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className='flex flex-col min-h-screen'>
      <Menu />
      <main className='flex-grow container mx-auto px-4 py-8'>
        <h1 className='text-3xl font-bold mb-8 text-center'>미디어</h1>

        {isLoading && (
          <div className='flex justify-center items-center h-64'>
            <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500'></div>
          </div>
        )}

        {error && (
          <div
            className='bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative'
            role='alert'
          >
            <span className='block sm:inline'>{error}</span>
          </div>
        )}

        {mounted && (
          <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'>
            {medias.map((media) => (
              <Link
                href={
                  media.videoUrl ||
                  `https://www.youtube.com/watch?v=${media.videoId}`
                }
                key={media.id}
                target='_blank'
                rel='noopener noreferrer'
                className='block'
              >
                <div className='bg-white shadow-md rounded-lg overflow-hidden hover:shadow-lg transition-shadow duration-300'>
                  {renderThumbnail(media)}
                  <div className='p-4 bg-white/90'>
                    <h2 className='text-lg font-semibold text-gray-800 line-clamp-2 mb-2'>
                      {getTitleString(media.title)}
                    </h2>
                    <p className='text-sm text-gray-700'>
                      {new Date(media.createdAt).toLocaleDateString(
                        currentLang === 'ko' ? 'ko-KR' : 'en-US',
                        {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                        },
                      )}
                    </p>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}

        {medias.length === 0 && !isLoading && !error && (
          <div className='text-center py-12'>
            <p className='text-xl text-gray-800 font-medium'>표시할 미디어가 없습니다.</p>
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
};

export default MediaPage;
