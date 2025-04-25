'use client';

import React from 'react';
import { Vote, VoteItem } from '@/types/interfaces';
import VoteRankCard from './VoteRankCard';

const CompletedVoteItems: React.FC<{
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
}> = ({ vote }) => {
  if (!vote.voteItems || vote.voteItems.length === 0) {
    return null;
  }

  const topThreeItems = [...vote.voteItems]
    .sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0))
    .slice(0, 3);

  if (topThreeItems.length === 0) {
    return null;
  }

  return (
    <div className='mt-4'>
      <div className='relative'>
        {/* 배경 디자인 요소 - 더 어둡고 과거의 느낌을 주는 그라데이션 */}
        <div className='absolute inset-0 bg-gradient-to-br from-gray-100/30 to-gray-200/30 rounded-xl opacity-50'></div>

        <div className='relative grid grid-cols-1 sm:grid-cols-3 items-center gap-4 py-3 mt-8'>
          {topThreeItems.map((item, index) => (
            <VoteRankCard
              key={item.id}
              item={item}
              rank={index + 1}
              className="opacity-80 grayscale"
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default CompletedVoteItems; 