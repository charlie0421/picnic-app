'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { getLocalizedString } from '@/utils/api/strings';
interface RewardItemProps {
  reward: Reward;
}

const RewardItem: React.FC<RewardItemProps> = ({ reward }) => {
  const title = reward.title as { [key: string]: string } | null;
  const displayTitle = getLocalizedString(title);

  return (
    <Link href={`/reward/${reward.id}`}>
      <div className="bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
        <div className="relative aspect-square">
          {reward.thumbnail ? (
            <Image
              src={getCdnImageUrl(reward.thumbnail, 320)}
              alt={displayTitle}
              width={320}
              height={320}
              className="w-full h-full object-cover"
              priority
            />
          ) : (
            <div className="w-full h-full bg-gray-100 flex items-center justify-center">
              <span className="text-gray-400">이미지 없음</span>
            </div>
          )}
        </div>
        <div className="p-4">
          <h3 className="text-lg font-semibold text-gray-800 truncate">
            {displayTitle}
          </h3>
        </div>
      </div>
    </Link>
  );
};

export default RewardItem; 