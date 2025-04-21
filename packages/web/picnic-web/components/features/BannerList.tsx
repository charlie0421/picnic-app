'use client';

import React, { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Banner } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

interface BannerListProps {
  banners: Banner[];
}

const BannerList: React.FC<BannerListProps> = ({ banners }) => {
  // 빈 배너 배열에 대한 처리
  const validBanners = Array.isArray(banners) ? banners : [];

  const [currentIndex, setCurrentIndex] = useState(0);
  const [isMobile, setIsMobile] = useState(false);
  const autoScrollRef = useRef<NodeJS.Timeout | null>(null);
  const [isPaused, setIsPaused] = useState(false);

  // 배너 리스트 로깅
  useEffect(() => {
    console.log('배너 리스트:', validBanners);
    console.log('배너 개수:', validBanners.length);
  }, [validBanners]);

  // 로깅 현재 인덱스
  useEffect(() => {
    console.log('현재 배너 인덱스:', currentIndex);
  }, [currentIndex]);

  // 모바일 여부 확인
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);

    return () => {
      window.removeEventListener('resize', checkMobile);
    };
  }, []);

  // 자동 스크롤 시작 함수
  const startAutoScroll = () => {
    if (validBanners.length <= 2) return;

    if (autoScrollRef.current) {
      clearInterval(autoScrollRef.current);
    }

    autoScrollRef.current = setInterval(() => {
      if (!isPaused) {
        setCurrentIndex((prev) => {
          const nextIndex = (prev + 1) % validBanners.length;
          console.log(`자동 스크롤: ${prev} -> ${nextIndex}`);
          return nextIndex;
        });
      }
    }, 5000);
  };

  // 자동 슬라이드 설정 (배너가 2개 초과일 경우에만)
  useEffect(() => {
    startAutoScroll();

    return () => {
      if (autoScrollRef.current) {
        clearInterval(autoScrollRef.current);
      }
    };
  }, [validBanners.length, isPaused]);

  // 마우스가 배너 위에 있을 때 자동 스크롤 일시 정지
  const handleMouseEnter = () => {
    setIsPaused(true);
  };

  // 마우스가 배너에서 벗어날 때 자동 스크롤 재개
  const handleMouseLeave = () => {
    setIsPaused(false);
  };

  // 다음 배너로 이동
  const nextBanner = () => {
    if (validBanners.length <= 2) return;

    const nextIndex = (currentIndex + 1) % validBanners.length;
    console.log(`다음 버튼: ${currentIndex} -> ${nextIndex}`);
    setCurrentIndex(nextIndex);
    startAutoScroll();
  };

  // 이전 배너로 이동
  const prevBanner = () => {
    if (validBanners.length <= 2) return;

    const prevIndex =
      (currentIndex - 1 + validBanners.length) % validBanners.length;
    console.log(`이전 버튼: ${currentIndex} -> ${prevIndex}`);
    setCurrentIndex(prevIndex);
    startAutoScroll();
  };

  // 특정 배너로 이동
  const goToBanner = (index: number) => {
    console.log(`인디케이터 클릭: ${currentIndex} -> ${index}`);
    setCurrentIndex(index);
    startAutoScroll();
  };

  // 배너 렌더링
  const renderBanner = (banner: Banner, index: number) => {
    try {
      const image = banner.image as { [key: string]: string } | null;

      return (
        <div key={banner.id || index} className='w-full h-full'>
          <Link href={banner.link || '#'}>
            <div className='relative w-full pb-[50.9%] bg-gray-200 overflow-hidden hover:shadow-lg transition-shadow'>
              {image ? (
                <Image
                  src={getCdnImageUrl(getLocalizedString(image), 786)}
                  alt={typeof banner.title === 'string' ? banner.title : '배너'}
                  fill
                  sizes={isMobile ? '100vw' : '50vw'}
                  className='object-cover'
                  priority
                />
              ) : (
                <div className='absolute inset-0 flex items-center justify-center'>
                  <span className='text-gray-600'>
                    {typeof banner.title === 'string' ? banner.title : '배너'}
                  </span>
                </div>
              )}
            </div>
          </Link>
        </div>
      );
    } catch (error) {
      console.error('배너 렌더링 오류:', error);
      return (
        <div key={index} className='w-full h-full'>
          <div className='relative w-full pb-[50.9%] bg-gray-200 overflow-hidden'>
            <div className='absolute inset-0 flex items-center justify-center'>
              <span className='text-gray-600'>배너 로드 오류</span>
            </div>
          </div>
        </div>
      );
    }
  };

  // 배너가 없는 경우 처리
  if (validBanners.length === 0) {
    return (
      <section>
        <div className='mb-4'>
          <div className='bg-gray-100 p-6 rounded-lg text-center'>
            <p className='text-gray-500'>현재 표시할 배너가 없습니다.</p>
          </div>
        </div>
      </section>
    );
  }

  // 배너가 2개 이하인 경우 그리드로 표시
  if (validBanners.length <= 2) {
    return (
      <section>
        <div className='mb-4'>
          <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
            {validBanners.map((banner, index) => renderBanner(banner, index))}
          </div>
        </div>
      </section>
    );
  }

  // 배너가 3개 이상인 경우 슬라이더로 표시
  return (
    <section>
      <div
        className='mb-4 relative'
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleMouseLeave}
      >
        <div className='relative overflow-hidden rounded-lg'>
          {/* 슬라이더 컨테이너 */}
          <div className='w-full overflow-hidden'>
            {isMobile ? (
              // 모바일: 한 배너씩 슬라이드
              <div
                className='flex transition-transform duration-300 ease-in-out'
                style={{
                  transform: `translateX(-${currentIndex * 100}%)`,
                  width: `${validBanners.length * 100}%`,
                }}
              >
                {validBanners.map((banner, index) => (
                  <div
                    key={banner.id || index}
                    style={{ width: `${100 / validBanners.length}%` }}
                  >
                    {renderBanner(banner, index)}
                  </div>
                ))}
              </div>
            ) : (
              // 데스크탑: 2개 배너 표시하면서 1개씩 슬라이드
              <div
                className='flex transition-transform duration-300 ease-in-out'
                style={{
                  transform: `translateX(-${currentIndex * 50}%)`,
                  width: `${validBanners.length * 50}%`,
                }}
              >
                {validBanners.map((banner, index) => (
                  <div
                    key={banner.id || index}
                    className='px-2'
                    style={{ width: '50%', float: 'left' }}
                  >
                    {renderBanner(banner, index)}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* 네비게이션 버튼 */}
          <button
            onClick={prevBanner}
            className='absolute left-2 top-1/2 transform -translate-y-1/2 bg-black/30 text-white rounded-full p-2 hover:bg-black/50 focus:outline-none z-10'
            aria-label='이전 배너'
          >
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-5 w-5'
              viewBox='0 0 20 20'
              fill='currentColor'
            >
              <path
                fillRule='evenodd'
                d='M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z'
                clipRule='evenodd'
              />
            </svg>
          </button>
          <button
            onClick={nextBanner}
            className='absolute right-2 top-1/2 transform -translate-y-1/2 bg-black/30 text-white rounded-full p-2 hover:bg-black/50 focus:outline-none z-10'
            aria-label='다음 배너'
          >
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-5 w-5'
              viewBox='0 0 20 20'
              fill='currentColor'
            >
              <path
                fillRule='evenodd'
                d='M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z'
                clipRule='evenodd'
              />
            </svg>
          </button>

          {/* 인디케이터 */}
          <div className='absolute bottom-2 left-1/2 transform -translate-x-1/2 flex space-x-2 z-10'>
            {validBanners.map((_, index) => (
              <button
                key={index}
                onClick={() => goToBanner(index)}
                className={`w-2 h-2 rounded-full focus:outline-none ${
                  index === currentIndex ? 'bg-white' : 'bg-white/50'
                }`}
                aria-label={`배너 ${index + 1}로 이동`}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default BannerList;
