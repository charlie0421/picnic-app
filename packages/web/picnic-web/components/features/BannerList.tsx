'use client';

import React, { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Banner } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

// 스와이프 기능을 위한 터치 이벤트 타입
interface TouchPosition {
  startX: number;
  endX: number;
}

interface BannerListProps {
  banners: Banner[];
}

const BannerList: React.FC<BannerListProps> = ({ banners }) => {
  const [currentBanner, setCurrentBanner] = useState(0);
  const [touchPosition, setTouchPosition] = useState<TouchPosition | null>(
    null,
  );
  const autoScrollRef = useRef<NodeJS.Timeout | null>(null);
  const bannerContainerRef = useRef<HTMLDivElement>(null);
  const [isMobile, setIsMobile] = useState(false);

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

  // 현재 표시 가능한 배너 수 계산
  const visibleCount = isMobile ? 1 : 2;

  // 배너 페이지 계산
  const maxPage = banners.length;

  // 자동 스크롤 설정 (배너가 2개 초과일 경우에만)
  useEffect(() => {
    // 2개 이하면 자동 스크롤 필요 없음
    if (banners.length <= 2) return;

    const startAutoScroll = () => {
      autoScrollRef.current = setInterval(() => {
        setCurrentBanner((prev) => (prev + 1) % maxPage);
      }, 5000);
    };

    startAutoScroll();

    return () => {
      if (autoScrollRef.current) {
        clearInterval(autoScrollRef.current);
      }
    };
  }, [banners.length, maxPage]);

  // 터치 시작 시 위치 저장
  const handleTouchStart = (e: React.TouchEvent) => {
    // 배너가 2개 이하면 스와이프 불필요
    if (banners.length <= 2) return;

    setTouchPosition({
      startX: e.touches[0].clientX,
      endX: e.touches[0].clientX,
    });
  };

  // 터치 이동 시 위치 업데이트
  const handleTouchMove = (e: React.TouchEvent) => {
    if (!touchPosition || banners.length <= 2) return;

    setTouchPosition({
      ...touchPosition,
      endX: e.touches[0].clientX,
    });
  };

  // 터치 종료 시 스와이프 처리
  const handleTouchEnd = () => {
    if (!touchPosition || banners.length <= 2) return;

    const diff = touchPosition.startX - touchPosition.endX;
    const threshold = 50; // 스와이프로 인정할 최소 거리

    if (diff > threshold) {
      // 왼쪽으로 스와이프 (다음 배너)
      setCurrentBanner((prev) => (prev + 1) % maxPage);
    } else if (diff < -threshold) {
      // 오른쪽으로 스와이프 (이전 배너)
      setCurrentBanner((prev) => (prev - 1 + maxPage) % maxPage);
    }

    setTouchPosition(null);

    // 자동 스크롤 재시작
    if (autoScrollRef.current && banners.length > 2) {
      clearInterval(autoScrollRef.current);
      autoScrollRef.current = setInterval(() => {
        setCurrentBanner((prev) => (prev + 1) % maxPage);
      }, 5000);
    }
  };

  // 배너 클릭 시 자동 스크롤 일시정지
  const handleBannerClick = () => {
    if (autoScrollRef.current && banners.length > 2) {
      clearInterval(autoScrollRef.current);
    }
  };

  // 다음 배너로 이동
  const nextBanner = () => {
    if (banners.length <= 2) return;

    setCurrentBanner((prev) => (prev + 1) % maxPage);

    // 자동 스크롤 재시작
    if (autoScrollRef.current && banners.length > 2) {
      clearInterval(autoScrollRef.current);
      autoScrollRef.current = setInterval(() => {
        setCurrentBanner((prev) => (prev + 1) % maxPage);
      }, 5000);
    }
  };

  // 이전 배너로 이동
  const prevBanner = () => {
    if (banners.length <= 2) return;

    setCurrentBanner((prev) => (prev - 1 + maxPage) % maxPage);

    // 자동 스크롤 재시작
    if (autoScrollRef.current && banners.length > 2) {
      clearInterval(autoScrollRef.current);
      autoScrollRef.current = setInterval(() => {
        setCurrentBanner((prev) => (prev + 1) % maxPage);
      }, 5000);
    }
  };

  // 배너 렌더링
  const renderBanner = (banner: Banner) => {
    const image = banner.image as { [key: string]: string } | null;

    return (
      <div
        key={banner.id}
        className='w-full h-full'
        onClick={handleBannerClick}
      >
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
  };

  return (
    <section>
      <div className='mb-4'>
        {banners.length === 0 ? (
          <div className='bg-gray-100 p-6 rounded-lg text-center'>
            <p className='text-gray-500'>현재 표시할 배너가 없습니다.</p>
          </div>
        ) : (
          <div
            className='relative overflow-hidden rounded-lg'
            ref={bannerContainerRef}
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
          >
            {/* 배너가 2개 이하일 때 */}
            {banners.length <= 2 ? (
              <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                {banners.map(renderBanner)}
              </div>
            ) : (
              /* 배너가 3개 이상일 때 슬라이드 */
              <>
                {/* 슬라이더 컨테이너 */}
                <div className='w-full overflow-hidden'>
                  {isMobile ? (
                    // 모바일: 한 배너씩 슬라이드
                    <div
                      className='flex transition-transform duration-300 ease-in-out w-full'
                      style={{
                        transform: `translateX(-${currentBanner * 100}%)`,
                        width: `${banners.length * 100}%`,
                      }}
                    >
                      {banners.map((banner) => (
                        <div
                          key={banner.id}
                          style={{ width: `${100 / banners.length}%` }}
                        >
                          {renderBanner(banner)}
                        </div>
                      ))}
                    </div>
                  ) : (
                    // 데스크탑: 2개 배너 표시하면서 1개씩 슬라이드
                    <div
                      className='flex transition-transform duration-300 ease-in-out w-full'
                      style={{
                        transform: `translateX(-${currentBanner * 50}%)`,
                        width: `${banners.length * 50}%`,
                      }}
                    >
                      {banners.map((banner) => (
                        <div
                          key={banner.id}
                          style={{ width: '50%' }}
                          className='px-2'
                        >
                          {renderBanner(banner)}
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* 화살표 네비게이션 (2개 초과일 때만) */}
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
                  {Array.from({ length: maxPage }).map((_, index) => (
                    <button
                      key={index}
                      onClick={() => setCurrentBanner(index)}
                      className={`w-2 h-2 rounded-full focus:outline-none ${
                        index === currentBanner ? 'bg-white' : 'bg-white/50'
                      }`}
                      aria-label={`배너 ${index + 1}로 이동`}
                    />
                  ))}
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </section>
  );
};

export default BannerList;
