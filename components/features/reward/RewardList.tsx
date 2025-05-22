'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import {Reward} from '@/types/interfaces';
import {getCdnImageUrl} from '@/utils/api/image';
import {getLocalizedString} from '@/utils/api/strings';

interface RewardListProps {
  rewards: Reward[];
  showViewAllLink?: boolean;
}

const RewardList: React.FC<RewardListProps> = ({
  rewards,
}) => {
  return (
    <section>
      {rewards.length === 0 ? (
        <div className='bg-gray-100 p-6 rounded-lg text-center'>
          <p className='text-gray-500'>표시할 리워드가 없습니다.</p>
        </div>
      ) : (
        <div className='grid grid-cols-2 md:grid-cols-4 gap-4'>
          {rewards.map((reward) => (
            <Link
              key={reward.id}
              href={`/rewards/${reward.id}`}
              className='bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-all duration-200'
            >
              <div className='aspect-square bg-gray-200 relative'>
                {reward.thumbnail ? (
                  <Image
                    src={getCdnImageUrl(reward.thumbnail, 320)}
                    alt={
                      typeof reward.title === 'string' ? reward.title : '리워드'
                    }
                    width={320}
                    height={320}
                    className='w-full h-full object-cover'
                    priority
                  />
                ) : (
                  <div className='w-full h-full flex items-center justify-center'>
                    <span className='text-gray-600'>리워드 이미지</span>
                  </div>
                )}
              </div>
              <div className='p-3'>
                <h3 className='font-medium mb-1 truncate text-gray-800'>
                  {getLocalizedString(
                    reward.title as { [key: string]: string } | null,
                  )}
                </h3>
              </div>
            </Link>
          ))}
        </div>
      )}
    </section>
  );
};

export default RewardList;
