'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { Banner, Reward, Vote } from '@/types/interfaces';
import Menu from '@/components/features/Menu';
import Footer from '@/components/layouts/Footer';
import BannerList from '@/components/features/BannerList';
import RewardList from '@/components/features/RewardList';
import VoteList from '@/components/features/VoteList';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { getBanners, getRewards, getVotes } from '@/utils/api/queries';

const VotePage: React.FC = () => {
  const [votes, setVotes] = useState<Vote[]>([]);
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [banners, setBanners] = useState<Banner[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const bannersData = await getBanners();
        console.log(bannersData);
        setBanners(bannersData);

        const rewardsData = await getRewards();
        console.log(rewardsData);
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

  return (
    <div className="min-h-screen">
      <div className="bg-gray-50 border-b">
        <div className="container mx-auto px-0">
          <Menu />
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center min-h-[300px]">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
        </div>
      ) : error ? (
        <div className="bg-red-100 text-red-700 p-4 rounded-md">
          {error}
        </div>
      ) : (
        <div className="container mx-auto px-4 py-6 space-y-10">
          <BannerList banners={banners} />
          <RewardList rewards={rewards} />
          <VoteList/>
        </div>
      )}

      <Footer />
    </div>
  );
};

export default VotePage; 