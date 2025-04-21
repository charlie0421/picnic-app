'use client';

import React, { useEffect, useState } from 'react';
import { Banner, Reward } from '@/types/interfaces';
import Menu from '@/components/features/Menu';
import Footer from '@/components/layouts/Footer';
import BannerList from '@/components/features/BannerList';
import VoteList from '@/components/features/VoteList';
import { getBanners, getRewards } from '@/utils/api/queries';

const VotePage: React.FC = () => {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);
        const bannersData = await getBanners();
        setBanners(bannersData);

        const rewardsData = await getRewards(4);
        setRewards(rewardsData);
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
    <div className='min-h-screen'>
      <div className='bg-gray-50 border-b'>
        <div className='container mx-auto px-0'>
          <Menu />
        </div>
      </div>

      {isLoading ? (
        <div className='flex justify-center items-center min-h-[300px]'>
          <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary'></div>
        </div>
      ) : error ? (
        <div className='bg-red-100 text-red-700 p-4 rounded-md'>{error}</div>
      ) : (
        <div className='container mx-auto px-4 py-6 space-y-10'>
          <BannerList banners={banners} />
          <VoteList />
        </div>
      )}

      <Footer />
    </div>
  );
};

export default VotePage;
