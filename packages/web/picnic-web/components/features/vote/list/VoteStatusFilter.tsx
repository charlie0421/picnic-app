import React from 'react';
import { useLanguageStore } from '@/stores/languageStore';

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];

interface VoteStatusFilterProps {
  selectedStatus: VoteStatus;
  onStatusChange: (status: VoteStatus) => void;
}

const VoteStatusFilter = React.memo(
  ({ selectedStatus, onStatusChange }: VoteStatusFilterProps) => {
    const { t } = useLanguageStore();

    const getButtonText = (status: VoteStatus) => {
      switch (status) {
        case VOTE_STATUS.ONGOING:
          return t('label_tabbar_vote_active');
        case VOTE_STATUS.UPCOMING:
          return t('label_tabbar_vote_upcoming');
        case VOTE_STATUS.COMPLETED:
          return t('label_tabbar_vote_end');
        default:
          return '';
      }
    };

    return (
      <div className='flex flex-wrap justify-end gap-1 sm:gap-1.5 bg-white/50 backdrop-blur-sm p-1.5 rounded-lg shadow-sm border border-gray-100'>
        <button
          onClick={() => onStatusChange(VOTE_STATUS.ONGOING)}
          className={`px-2 py-1 sm:px-2.5 sm:py-1 rounded-lg text-xs font-medium transition-all duration-200 ${
            selectedStatus === VOTE_STATUS.ONGOING
              ? 'bg-primary text-white shadow-sm transform scale-[1.02]'
              : 'bg-gray-50 text-gray-600 hover:bg-primary/10 hover:text-primary hover:shadow-sm'
          }`}
          aria-label={t('label_tabbar_vote_active')}
          aria-pressed={selectedStatus === VOTE_STATUS.ONGOING}
        >
          {getButtonText(VOTE_STATUS.ONGOING)}
        </button>
        <button
          onClick={() => onStatusChange(VOTE_STATUS.UPCOMING)}
          className={`px-2 py-1 sm:px-2.5 sm:py-1 rounded-lg text-xs font-medium transition-all duration-200 ${
            selectedStatus === VOTE_STATUS.UPCOMING
              ? 'bg-primary text-white shadow-sm transform scale-[1.02]'
              : 'bg-gray-50 text-gray-600 hover:bg-primary/10 hover:text-primary hover:shadow-sm'
          }`}
          aria-label={t('label_tabbar_vote_upcoming')}
          aria-pressed={selectedStatus === VOTE_STATUS.UPCOMING}
        >
          {getButtonText(VOTE_STATUS.UPCOMING)}
        </button>
        <button
          onClick={() => onStatusChange(VOTE_STATUS.COMPLETED)}
          className={`px-2 py-1 sm:px-2.5 sm:py-1 rounded-lg text-xs font-medium transition-all duration-200 ${
            selectedStatus === VOTE_STATUS.COMPLETED
              ? 'bg-primary text-white shadow-sm transform scale-[1.02]'
              : 'bg-gray-50 text-gray-600 hover:bg-primary/10 hover:text-primary hover:shadow-sm'
          }`}
          aria-label={t('label_tabbar_vote_end')}
          aria-pressed={selectedStatus === VOTE_STATUS.COMPLETED}
        >
          {getButtonText(VOTE_STATUS.COMPLETED)}
        </button>
      </div>
    );
  },
);

VoteStatusFilter.displayName = 'VoteStatusFilter';

export default VoteStatusFilter; 