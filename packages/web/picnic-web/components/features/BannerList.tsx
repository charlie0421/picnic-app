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
  const [isTablet, setIsTablet] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [mounted, setMounted] = useState(false);
  const autoScrollRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

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

  // 화면 크기 감지
  useEffect(() => {
    if (!mounted) return;

    const checkScreenSize = () => {
      const width = window.innerWidth;
      if (width < 640) {
        setIsMobile(true);
        setIsTablet(false);
      } else if (width < 1024) {
        setIsMobile(false);
        setIsTablet(true);
      } else {
        setIsMobile(false);
        setIsTablet(false);
      }
    };

    checkScreenSize();
    window.addEventListener('resize', checkScreenSize);

    return () => {
      window.removeEventListener('resize', checkScreenSize);
    };
  }, [mounted]);

  // 다음 배너로 이동
  const nextBanner = useCallback(() => {
    if (banners.length <= 3 && !isMobile && !isTablet) return;
    setCurrentIndex((prev) => {
      const totalGroups = isMobile || isTablet 
        ? Math.ceil(banners.length / 2) 
        : banners.length;
      
      const next = prev + 1;
      if (next >= totalGroups) {
        return 0;
      }
      return next;
    });
  }, [banners.length, isMobile, isTablet]);

  // 이전 배너로 이동
  const prevBanner = useCallback(() => {
    if (banners.length <= 3 && !isMobile && !isTablet) return;
    setCurrentIndex((prev) => {
      const totalGroups = isMobile || isTablet 
        ? Math.ceil(banners.length / 2) 
        : banners.length;
      
      const next = prev - 1;
      if (next < 0) {
        return totalGroups - 1;
      }
      return next;
    });
  }, [banners.length, isMobile, isTablet]);

  // 자동 스크롤 시작
  useEffect(() => {
    if (banners.length <= 3 && !isMobile && !isTablet) return;

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
  }, [banners.length, isPaused, nextBanner, isMobile, isTablet]);

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
                sizes="(max-width: 639px) 50vw, (max-width: 1023px) 50vw, 33.33vw"
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

  // 서버 사이드에서는 기본값 사용
  if (typeof window === 'undefined') {
    return <LoadingSpinner />;
  }

  if (isLoading) {
    return <LoadingSpinner />;
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
          <div className='grid grid-cols-2 lg:grid-cols-3 gap-4'>
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
    
    // 디바이스 크기별 표시할 배너 수
    const countToShow = isMobile || isTablet ? 2 : 3;

    for (let i = 0; i < countToShow; i++) {
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
                transform: isMobile || isTablet
                  ? `translateX(-${currentIndex * 100}%)`
                  : `translateX(0%)`,
              }}
            >
              {isMobile || isTablet ? (
                // 모바일/태블릿: 쌍으로 슬라이드(한 화면에 2개씩)
                [...Array(Math.ceil(banners.length / 2))].map((_, groupIndex) => {
                  const startIdx = (groupIndex * 2) % banners.length;
                  const bannerPair = [
                    banners[startIdx],
                    banners[(startIdx + 1) % banners.length]
                  ].filter(Boolean); // 마지막에 1개만 남을 경우 대비
                  
                  return (
                    <div key={`group-${groupIndex}`} className="w-full flex-shrink-0">
                      <div className="grid grid-cols-2 gap-2">
                        {bannerPair.map((banner) => (
                          <div key={banner.id} className="w-full">
                            {renderBanner(banner)}
                          </div>
                        ))}
                      </div>
                    </div>
                  );
                })
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
