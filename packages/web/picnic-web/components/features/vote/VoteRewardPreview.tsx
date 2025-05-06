import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';
import { getLocalizedString } from '@/utils/api/strings';
interface VoteRewardPreviewProps {
  rewards: Reward[];
  className?: string;
  compact?: boolean;
  isSticky?: boolean;
}

const VoteRewardPreview: React.FC<VoteRewardPreviewProps> = ({ 
  rewards, 
  className = '',
  compact = false,
  isSticky = false
}) => {
  const { t, currentLanguage } = useLanguageStore();
  const [mounted, setMounted] = useState(false);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

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
                  alt={mounted ? getLocalizedString(reward.title) : typeof reward.title === 'string' ? reward.title : (reward.title as Record<string, string>)?.[currentLanguage] || (reward.title as Record<string, string>)?.['en'] || ''}
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
    <div className={`bg-cream-50 rounded-lg p-2 ${className}`}>
      <div 
        className='flex items-center justify-between cursor-pointer' 
        onClick={() => setExpanded(!expanded)}
      >
        <div className='flex items-center gap-2'>
          <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-brown-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
          </svg>
          <span className='text-brown-600 text-sm font-medium'>
            {rewards.length}개의 리워드가 있습니다
          </span>
        </div>
        <svg 
          xmlns="http://www.w3.org/2000/svg" 
          className={`h-4 w-4 text-brown-600 transition-transform ${expanded ? 'rotate-180' : ''}`} 
          fill="none" 
          viewBox="0 0 24 24" 
          stroke="currentColor"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </div>

      {expanded && (
        <div className='mt-2 overflow-x-auto'>
          <div className='flex space-x-2 pb-1'>
            {rewards.map((reward) => (
              <div
                key={reward.id}
                className='bg-white rounded-lg border border-cream-100 flex-shrink-0'
                style={{ width: '180px' }}
              >
                <div className='p-2'>
                  <div className='w-full h-16 rounded-lg overflow-hidden relative mb-2'>
                    {reward.overviewImages?.[0] && (
                      <Image
                        src={getCdnImageUrl(reward.overviewImages[0])}
                        alt={mounted ? getLocalizedString(reward.title) : typeof reward.title === 'string' ? reward.title : (reward.title as Record<string, string>)?.[currentLanguage] || (reward.title as Record<string, string>)?.['en'] || ''}
                        fill
                        className='object-cover'
                      />
                    )}
                  </div>
                  <p className='text-xs font-medium text-gray-900 truncate'>
                    {mounted ? getLocalizedString(reward.title) : typeof reward.title === 'string' ? reward.title : (reward.title as Record<string, string>)?.[currentLanguage] || (reward.title as Record<string, string>)?.['en'] || ''}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default VoteRewardPreview; 