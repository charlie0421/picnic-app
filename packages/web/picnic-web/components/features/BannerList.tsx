'use client';

import React, { useEffect, useState, useRef, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Banner } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';
import { getBanners } from '@/utils/api/queries';
import LoadingSpinner from '@/components/ui/LoadingSpinner';

const BannerList: React.FC = () => {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isMobile, setIsMobile] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const autoScrollRef = useRef<NodeJS.Timeout | null>(null);

  // 배너 데이터 가져오기
  useEffect(() => {
    const fetchBanners = async () => {
      try {
        setIsLoading(true);
        const bannersData = await getBanners();
        setBanners(bannersData);
      } catch (error) {
        console.error('배너 데이터를 가져오는 중 오류가 발생했습니다:', error);
        setError('배너를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setIsLoading(false);
      }
    };

    fetchBanners();
  }, []);

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

  // 다음 배너로 이동
  const nextBanner = useCallback(() => {
    if (banners.length <= 3) return;
    setCurrentIndex((prev) => {
      const next = prev + 1;
      if (next >= banners.length) {
        return 0;
      }
      return next;
    });
  }, [banners.length]);

  // 이전 배너로 이동
  const prevBanner = useCallback(() => {
    if (banners.length <= 3) return;
    setCurrentIndex((prev) => {
      const next = prev - 1;
      if (next < 0) {
        return banners.length - 1;
      }
      return next;
    });
  }, [banners.length]);

  // 자동 스크롤 시작
  useEffect(() => {
    if (banners.length <= 3) return;

    const startAutoScroll = () => {
      if (autoScrollRef.current) {
        clearInterval(autoScrollRef.current);
      }

      autoScrollRef.current = setInterval(() => {
        if (!isPaused) {
          nextBanner();
        }
      }, 5000);
    };

    startAutoScroll();

    return () => {
      if (autoScrollRef.current) {
        clearInterval(autoScrollRef.current);
      }
    };
  }, [banners.length, isPaused, nextBanner]);

  // 배너 렌더링
  const renderBanner = (banner: Banner) => {
    try {
      const image = banner.image as { [key: string]: string } | null;

      return (
        <Link href={banner.link || '#'}>
          <div className='relative w-full pb-[50.9%] bg-gray-200 overflow-hidden hover:shadow-lg transition-shadow'>
            {image ? (
              <Image
                src={getCdnImageUrl(getLocalizedString(image), 786)}
                alt={typeof banner.title === 'string' ? banner.title : '배너'}
                fill
                sizes={isMobile ? '100vw' : '33.33vw'}
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
      );
    } catch (error) {
      console.error('배너 렌더링 오류:', error);
      return (
        <div className='relative w-full pb-[50.9%] bg-gray-200 overflow-hidden'>
          <div className='absolute inset-0 flex items-center justify-center'>
            <span className='text-gray-600'>배너 로드 오류</span>
          </div>
        </div>
      );
    }
  };

  if (isLoading) {
    return <LoadingSpinner className="min-h-[300px]" />;
  }

  if (error) {
    return (
      <section>
        <div className='mb-4'>
          <div className='bg-red-100 p-6 rounded-lg text-center'>
            <p className='text-red-700'>{error}</p>
          </div>
        </div>
      </section>
    );
  }

  // 배너가 없는 경우 처리
  if (banners.length === 0) {
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

  // 배너가 3개 이하인 경우 그리드로 표시
  if (banners.length <= 3) {
    return (
      <section>
        <div className='mb-4'>
          <div className='grid grid-cols-1 md:grid-cols-3 gap-4'>
            {banners.map((banner) => (
              <div key={banner.id} className="w-full">
                {renderBanner(banner)}
              </div>
            ))}
          </div>
        </div>
      </section>
    );
  }

  // 현재 인덱스를 기준으로 표시할 배너들을 계산
  const getVisibleBanners = () => {
    const result = [];
    const totalBanners = banners.length;

    for (let i = 0; i < (isMobile ? 1 : 3); i++) {
      const index = (currentIndex + i) % totalBanners;
      result.push(banners[index]);
    }

    return result;
  };

  return (
    <section>
      <div
        className='mb-4 relative'
        onMouseEnter={() => setIsPaused(true)}
        onMouseLeave={() => setIsPaused(false)}
      >
        <div className='relative overflow-hidden rounded-lg'>
          <div className='w-full overflow-hidden'>
            <div
              className='flex transition-all duration-500 ease-in-out'
              style={{
                transform: isMobile
                  ? `translateX(-${currentIndex * 100}%)`
                  : `translateX(0%)`,
              }}
            >
              {isMobile ? (
                // 모바일: 전체 배너를 한 번에 하나씩 표시
                banners.map((banner, index) => (
                  <div
                    key={`${banner.id}-${index}`}
                    className="w-full flex-shrink-0"
                  >
                    {renderBanner(banner)}
                  </div>
                ))
              ) : (
                // 데스크탑: 현재 보이는 3개의 배너만 표시
                <div className="w-full grid grid-cols-3 gap-4 transition-all duration-500 ease-in-out">
                  {getVisibleBanners().map((banner, index) => (
                    <div
                      key={`${banner.id}-${index}`}
                      className="w-full"
                    >
                      {renderBanner(banner)}
                    </div>
                  ))}
                </div>
              )}
            </div>
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
        </div>
      </div>
    </section>
  );
};

export default BannerList;
