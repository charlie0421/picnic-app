import React from 'react';
import VoteInfiniteLoading from './VoteInfiniteLoading';
import { useLanguageStore } from '@/stores/languageStore';

interface VotePaginationProps {
  hasMore: boolean;
  isLoading: boolean;
  isTransitioning: boolean;
  onLoadMore: () => void;
}

const VotePagination: React.FC<VotePaginationProps> = ({
  hasMore,
  isLoading,
  isTransitioning,
  onLoadMore,
}) => {
  const { t } = useLanguageStore();

  if (!hasMore) return null;

  return (
    <div className='flex justify-center mt-8'>
      <button
        onClick={onLoadMore}
        className='px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors duration-200 flex items-center gap-2'
        disabled={isLoading || isTransitioning}
      >
        {isLoading ? (
          <>
            <VoteInfiniteLoading />
            <span>Loading...</span>
          </>
        ) : (
          <>
            <span>{t('label_list_more')}</span>
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-4 w-4'
              viewBox='0 0 20 20'
              fill='currentColor'
            >
              <path
                fillRule='evenodd'
                d='M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z'
                clipRule='evenodd'
              />
            </svg>
          </>
        )}
      </button>
    </div>
  );
};

export default VotePagination; 