'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { getLocalizedString } from '@/utils/api/strings';
import VoteRewardPreview from './vote/VoteRewardPreview';

interface VoteItemProps {
  vote: Vote;
}

const VoteItem: React.FC<VoteItemProps> = ({ vote }) => {
  return (
    <Link href={`/vote/${vote.id}`}>
      <div className="bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
        <div className="relative aspect-square">
          {vote.mainImage ? (
            <Image
              src={getCdnImageUrl(vote.mainImage, 320)}
              alt={vote.title}
              width={320}
              height={320}
              className="w-full h-full object-cover md:w-[320px] md:h-[320px] w-[120px] h-[120px]"
              priority
            />
          ) : (
            <div className="w-full h-full bg-gray-100 flex items-center justify-center">
              <span className="text-gray-400 text-xs md:text-base">이미지 없음</span>
            </div>
          )}
        </div>
        <div className="p-2 md:p-3">
          <div className="flex items-start justify-between gap-2">
            {vote.rewards && vote.rewards.length > 0 && (
              <div>
                <VoteRewardPreview rewards={vote.rewards} />
              </div>
            )}
            <h3 className="text-xs md:text-base font-medium text-gray-800 truncate">
              {getLocalizedString(vote.title)}
            </h3>
          </div>
        </div>
      </div>
    </Link>
  );
};

export default VoteItem; 