import React from 'react';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getLocalizedString, getCdnImageUrl } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';

interface VoteRewardPreviewProps {
  rewards: Reward[];
  className?: string;
  compact?: boolean;
}

const VoteRewardPreview: React.FC<VoteRewardPreviewProps> = ({ 
  rewards, 
  className = '',
  compact = false 
}) => {
  const { t } = useLanguageStore();

  if (!rewards.length) return null;

  if (compact) {
    return (
      <div className={`flex items-center gap-2 ${className}`}>
        <div className='flex items-center gap-1 px-2 py-1 bg-cream-50 rounded-full'>
          <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-brown-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
          </svg>
          <span className='text-xs font-medium text-brown-600'>
            {rewards.length}
          </span>
        </div>
        <div className='flex -space-x-2'>
          {rewards.slice(0, 3).map((reward, index) => (
            <div
              key={reward.id}
              className='w-6 h-6 rounded-full border-2 border-white overflow-hidden relative bg-white'
              style={{ zIndex: 3 - index }}
            >
              {reward.overviewImages?.[0] && (
                <Image
                  src={getCdnImageUrl(reward.overviewImages[0])}
                  alt={getLocalizedString(reward.title)}
                  fill
                  className='object-cover'
                />
              )}
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-cream-50 rounded-lg p-4 ${className}`}>
      <div className='flex items-center gap-2 mb-4'>
        <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-brown-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
        </svg>
        <span className='text-brown-600 font-medium'>
          {rewards.length} reward
        </span>
      </div>

      {rewards.map((reward) => (
        <div
          key={reward.id}
          className='bg-white rounded-lg overflow-hidden border border-cream-100 mb-2 last:mb-0'
        >
          <div className='flex items-center p-3'>
            <div className='w-12 h-12 rounded-lg overflow-hidden relative flex-shrink-0 mr-3'>
              {reward.overviewImages?.[0] && (
                <Image
                  src={getCdnImageUrl(reward.overviewImages[0])}
                  alt={getLocalizedString(reward.title)}
                  fill
                  className='object-cover'
                />
              )}
            </div>
            <div className='flex-1'>
              <p className='text-base font-medium text-gray-900'>
                {getLocalizedString(reward.title)}
              </p>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default VoteRewardPreview; 