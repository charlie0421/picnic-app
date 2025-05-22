'use client';

import React, {useEffect, useState} from 'react';
import {Reward} from '@/types/interfaces';
import RewardList from '@/components/features/reward/RewardList';
import {getRewards} from '@/utils/api/queries';
import {useNavigation} from '@/contexts/NavigationContext';
import {PortalType} from '@/utils/enums';

const RewardsPage: React.FC = () => {
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { setCurrentPortalType } = useNavigation();

  // 현재 포털 타입을 REWARDS로 설정
  useEffect(() => {
    setCurrentPortalType(PortalType.VOTE);
  }, [setCurrentPortalType]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const rewardsData = await getRewards();
        setRewards(rewardsData);
        setIsLoading(false);
      } catch (error) {
        console.error('데이터를 가져오는 중 오류가 발생했습니다:', error);
        setError('데이터를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  if (isLoading) {
    return (
      <div className='flex justify-center items-center min-h-[300px]'>
        <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary'></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className='bg-red-100 text-red-700 p-4 rounded-md'>{error}</div>
    );
  }

  return (
    <div className='container mx-auto px-4 py-6 space-y-10'>
      <RewardList rewards={rewards}/>
    </div>
  );
};

export default RewardsPage;
