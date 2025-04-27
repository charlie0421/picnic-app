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
    <div className='flex justify-center items-center gap-2 md:gap-0.5 w-full max-w-full overflow-x-auto px-2 py-2'>
      {topThreeItems.map((item, index) => (
        <VoteRankCard
          key={item.id}
          item={item}
          rank={index + 1}
          className="opacity-80 grayscale"
        />
      ))}
    </div>
  );
};

export default CompletedVoteItems; 