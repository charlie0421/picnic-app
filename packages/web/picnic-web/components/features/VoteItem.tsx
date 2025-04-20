'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

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
            {getLocalizedString(vote.title)}
          </h3>
        </div>
      </div>
    </Link>
  );
};

export default VoteItem; 