'use client';

import React, { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getRewardById } from '@/utils/api/queries';
import { getCdnImageUrl } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';
import { getLocalizedJson, getLocalizedString } from '@/utils/api/strings';
import RewardImageGallery from '@/components/features/reward/RewardImageGallery';
import RewardTabs from '@/components/features/reward/RewardTabs';
import RewardLocationInfo from '@/components/features/reward/RewardLocationInfo';
import RewardSizeGuide from '@/components/features/reward/RewardSizeGuide';

const RewardDetailPage = () => {
  const params = useParams();
  const { id } = params;
  const { currentLanguage } = useLanguageStore();
  const [reward, setReward] = useState<Reward | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [activeTab, setActiveTab] = useState<'overview' | 'location' | 'size'>(
    'overview',
  );
  const { t } = useLanguageStore();

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
      <div className='flex justify-center items-center min-h-[calc(100vh-64px)]'>
        <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary'></div>
      </div>
    );
  }

  if (!reward) {
    return (
      <div className='container mx-auto px-4 py-10'>
        <div className='bg-red-50 text-red-700 p-6 rounded-lg text-center'>
          <p>리워드를 찾을 수 없습니다.</p>
        </div>
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
  const locationInfo = getLocalizedJson(reward.location) || null;

  // 다국어 크기 가이드 정보 처리
  const sizeGuideInfo = getLocalizedJson(reward.sizeGuide) || null;

  return (
    <div className='container mx-auto px-4 py-8'>
      <div className='mb-8 text-gray-700'>
        <h1 className='text-3xl font-bold mb-4'>{title}</h1>
      </div>

      {/* 탭 메뉴 */}
      <RewardTabs
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        setCurrentImageIndex={setCurrentImageIndex}
        t={t}
      />

      {/* 이미지 갤러리 */}
      <div className='mb-8'>
        {currentImages.length > 0 ? (
          <RewardImageGallery
            images={currentImages}
            title={title}
            currentImageIndex={currentImageIndex}
            setCurrentImageIndex={setCurrentImageIndex}
          />
        ) : (
          <div className='w-full aspect-video bg-gray-100 rounded-lg flex items-center justify-center'>
            <p className='text-gray-500'>이미지가 없습니다</p>
          </div>
        )}
      </div>

      {/* 위치 정보 */}
      {activeTab === 'location' && locationInfo && (
        <RewardLocationInfo locationInfo={locationInfo} />
      )}

      {/* 사이즈 가이드 */}
      {activeTab === 'size' && sizeGuideInfo && (
        <RewardSizeGuide sizeGuideInfo={sizeGuideInfo} />
      )}
    </div>
  );
};

export default RewardDetailPage;
