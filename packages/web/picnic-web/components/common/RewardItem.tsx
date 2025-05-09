import React from 'react';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { getLocalizedString } from '@/utils/api/strings';

const RewardItem = React.memo(({ reward }: { reward: Reward }) => (
  <div className='flex items-center bg-white rounded-lg p-2 shadow-sm border border-yellow-200 w-full'>
    {reward.thumbnail ? (
      <div className='w-10 h-10 rounded overflow-hidden mr-2'>
        <Image
          src={getCdnImageUrl(reward.thumbnail)}
          alt={getLocalizedString(reward.title)}
          width={40}
          height={40}
          className='w-full h-full object-cover'
        />
      </div>
    ) : (
      <div className='w-10 h-10 rounded overflow-hidden mr-2 bg-yellow-100 flex items-center justify-center'>
        <svg
          xmlns='http://www.w3.org/2000/svg'
          className='h-5 w-5 text-yellow-400'
          viewBox='0 0 20 20'
          fill='currentColor'
        >
          <path
            fillRule='evenodd'
            d='M5 5a3 3 0 015-2.236A3 3 0 0114.83 6H16a2 2 0 110 4h-5V9a1 1 0 10-2 0v1H4a2 2 0 110-4h1.17C5.06 5.687 5 5.35 5 5zm4 1V5a1 1 0 10-1 1h1zm3 0a1 1 0 10-1-1v1h1z'
            clipRule='evenodd'
          />
          <path d='M9 11H3v5a2 2 0 002 2h4v-7zM11 18h4a2 2 0 002-2v-5h-6v7z' />
        </svg>
      </div>
    )}
    <div className='flex-1 min-w-0'>
      <div className='text-sm font-medium text-gray-900 truncate'>
        {getLocalizedString(reward.title) || '리워드 정보'}
      </div>
    </div>
  </div>
));

RewardItem.displayName = 'RewardItem';

export default RewardItem;
