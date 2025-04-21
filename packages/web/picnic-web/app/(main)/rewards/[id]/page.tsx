'use client';

import React, { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';
import Menu from '@/components/features/Menu';
import Footer from '@/components/layouts/Footer';
import { Reward } from '@/types/interfaces';
import { getRewardById } from '@/utils/api/queries';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';
import { useLanguage } from '@/contexts/LanguageContext';

const RewardDetailPage = () => {
  const params = useParams();
  const { id } = params;
  const { currentLang } = useLanguage();
  const [reward, setReward] = useState<Reward | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [activeTab, setActiveTab] = useState<'overview' | 'location' | 'size'>(
    'overview',
  );

  useEffect(() => {
    const fetchReward = async () => {
      if (!id) return;

      try {
        const rewardData = await getRewardById(id as string);
        setReward(rewardData);
      } catch (error) {
        console.error('리워드 정보를 가져오는 중 오류가 발생했습니다:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchReward();
  }, [id]);

  if (loading) {
    return (
      <div className='min-h-screen'>
        <div className='bg-gray-50 border-b'>
          <div className='container mx-auto px-0'>
            <Menu />
          </div>
        </div>
        <div className='flex justify-center items-center min-h-[calc(100vh-64px)]'>
          <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary'></div>
        </div>
      </div>
    );
  }

  if (!reward) {
    return (
      <div className='min-h-screen'>
        <div className='bg-gray-50 border-b'>
          <div className='container mx-auto px-0'>
            <Menu />
          </div>
        </div>
        <div className='container mx-auto px-4 py-10'>
          <div className='bg-red-50 text-red-700 p-6 rounded-lg text-center'>
            <p>리워드를 찾을 수 없습니다.</p>
          </div>
        </div>
        <Footer />
      </div>
    );
  }

  const title =
    getLocalizedString(reward.title as { [key: string]: string } | null) ||
    '제목 없음';
  const overviewImages = reward.overviewImages || [];
  const locationImages = reward.locationImages || [];
  const sizeGuideImages = reward.sizeGuideImages || [];

  // 현재 활성화된 탭에 따라 이미지 배열 선택
  const currentImages = (() => {
    switch (activeTab) {
      case 'overview':
        return overviewImages;
      case 'location':
        return locationImages;
      case 'size':
        return sizeGuideImages;
      default:
        return overviewImages;
    }
  })();

  // 다국어 위치 정보 처리
  const locationInfo = reward.location
    ? (reward.location as any)[currentLang] || (reward.location as any)['ko']
    : null;

  // 다국어 크기 가이드 정보 처리
  const sizeGuideInfo = reward.sizeGuide
    ? (reward.sizeGuide as any)[currentLang] || (reward.sizeGuide as any)['ko']
    : null;

  return (
    <div className='min-h-screen'>
      <div className='bg-gray-50 border-b'>
        <div className='container mx-auto px-0'>
          <Menu />
        </div>
      </div>

      <div className='container mx-auto px-4 py-8'>
        <div className='mb-8'>
          <h1 className='text-3xl font-bold mb-4'>{title}</h1>
        </div>

        {/* 탭 메뉴 */}
        <div className='flex border-b border-gray-200 mb-6'>
          <button
            className={`px-4 py-2 font-medium ${
              activeTab === 'overview'
                ? 'text-primary border-b-2 border-primary'
                : 'text-gray-500'
            }`}
            onClick={() => {
              setActiveTab('overview');
              setCurrentImageIndex(0);
            }}
          >
            개요
          </button>
          <button
            className={`px-4 py-2 font-medium ${
              activeTab === 'location'
                ? 'text-primary border-b-2 border-primary'
                : 'text-gray-500'
            }`}
            onClick={() => {
              setActiveTab('location');
              setCurrentImageIndex(0);
            }}
          >
            위치
          </button>
          <button
            className={`px-4 py-2 font-medium ${
              activeTab === 'size'
                ? 'text-primary border-b-2 border-primary'
                : 'text-gray-500'
            }`}
            onClick={() => {
              setActiveTab('size');
              setCurrentImageIndex(0);
            }}
          >
            사이즈
          </button>
        </div>

        {/* 이미지 갤러리 */}
        <div className='mb-8'>
          {currentImages.length > 0 ? (
            <div>
              <div className='relative w-full aspect-video bg-gray-100 rounded-lg overflow-hidden mb-4'>
                {/* 이전 이미지 버튼 */}
                {currentImages.length > 1 && (
                  <button
                    onClick={() =>
                      setCurrentImageIndex((prev) =>
                        prev === 0 ? currentImages.length - 1 : prev - 1,
                      )
                    }
                    className='absolute left-2 top-1/2 z-10 transform -translate-y-1/2 bg-white/80 rounded-full p-2 shadow-md hover:bg-white transition'
                    aria-label='이전 이미지'
                  >
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      fill='none'
                      viewBox='0 0 24 24'
                      strokeWidth={1.5}
                      stroke='currentColor'
                      className='w-6 h-6'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        d='M15.75 19.5L8.25 12l7.5-7.5'
                      />
                    </svg>
                  </button>
                )}

                <Image
                  src={getCdnImageUrl(currentImages[currentImageIndex])}
                  alt={`${title} 이미지 ${currentImageIndex + 1}`}
                  fill
                  className='object-contain'
                  priority
                />

                {/* 다음 이미지 버튼 */}
                {currentImages.length > 1 && (
                  <button
                    onClick={() =>
                      setCurrentImageIndex((prev) =>
                        prev === currentImages.length - 1 ? 0 : prev + 1,
                      )
                    }
                    className='absolute right-2 top-1/2 z-10 transform -translate-y-1/2 bg-white/80 rounded-full p-2 shadow-md hover:bg-white transition'
                    aria-label='다음 이미지'
                  >
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      fill='none'
                      viewBox='0 0 24 24'
                      strokeWidth={1.5}
                      stroke='currentColor'
                      className='w-6 h-6'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        d='M8.25 4.5l7.5 7.5-7.5 7.5'
                      />
                    </svg>
                  </button>
                )}

                {/* 이미지 카운터 표시 */}
                {currentImages.length > 1 && (
                  <div className='absolute bottom-2 right-2 bg-black/60 text-white px-3 py-1 rounded-full text-sm'>
                    {currentImageIndex + 1} / {currentImages.length}
                  </div>
                )}
              </div>

              {currentImages.length > 1 && (
                <div className='flex overflow-x-auto space-x-2 py-2'>
                  {currentImages.map((image, index) => (
                    <div
                      key={index}
                      onClick={() => setCurrentImageIndex(index)}
                      className={`relative w-20 h-20 flex-shrink-0 cursor-pointer rounded-md overflow-hidden ${
                        index === currentImageIndex ? 'ring-2 ring-primary' : ''
                      }`}
                    >
                      <Image
                        src={getCdnImageUrl(image)}
                        alt={`${title} 썸네일 ${index + 1}`}
                        fill
                        className='object-cover'
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          ) : (
            <div className='w-full aspect-video bg-gray-100 rounded-lg flex items-center justify-center'>
              <p className='text-gray-500'>이미지가 없습니다</p>
            </div>
          )}
        </div>

        {/* 위치 정보 */}
        {activeTab === 'location' && locationInfo && (
          <div className='mt-8'>
            <h2 className='text-xl font-semibold mb-4'>위치 정보</h2>

            <div className='bg-gray-50 p-6 rounded-lg'>
              {locationInfo.desc && locationInfo.desc.length > 0 && (
                <div className='mb-4'>
                  <h3 className='text-lg font-medium mb-2'>설명</h3>
                  {locationInfo.desc.map((desc: string, index: number) => (
                    <p
                      key={index}
                      className='text-gray-700 whitespace-pre-line'
                    >
                      {desc}
                    </p>
                  ))}
                </div>
              )}

              {locationInfo.address && locationInfo.address.length > 0 && (
                <div className='mb-4'>
                  <h3 className='text-lg font-medium mb-2'>주소</h3>
                  {locationInfo.address.map(
                    (address: string, index: number) => (
                      <p key={index} className='text-gray-700'>
                        {address}
                      </p>
                    ),
                  )}
                </div>
              )}
            </div>
          </div>
        )}

        {/* 사이즈 가이드 */}
        {activeTab === 'size' && sizeGuideInfo && (
          <div className='mt-8'>
            <h2 className='text-xl font-semibold mb-4'>사이즈 가이드</h2>

            <div className='space-y-6'>
              {Array.isArray(sizeGuideInfo) &&
                sizeGuideInfo.map((sizeItem: any, index: number) => (
                  <div key={index} className='bg-gray-50 p-4 rounded-lg'>
                    {sizeItem.desc && sizeItem.desc.length > 0 && (
                      <div className='mb-2'>
                        {sizeItem.desc.map(
                          (desc: string, descIndex: number) => (
                            <p key={descIndex} className='text-gray-700'>
                              {desc}
                            </p>
                          ),
                        )}
                      </div>
                    )}
                  </div>
                ))}
            </div>
          </div>
        )}
      </div>

      <Footer />
    </div>
  );
};

export default RewardDetailPage;
