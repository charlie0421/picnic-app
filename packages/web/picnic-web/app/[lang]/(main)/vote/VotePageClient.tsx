'use client';

import React from 'react';
import BannerList from '@/components/features/BannerList';
import VoteList from '@/components/features/vote/list/VoteList';

const VotePageClient: React.FC = () => {
  return (
    <div className='container mx-auto px-4 py-6 space-y-4'>
      <BannerList />
      <VoteList />
    </div>
  );
};

export default VotePageClient; 