import React from 'react';

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];

interface VoteEmptyStateProps {
  selectedStatus: VoteStatus;
}

const VoteEmptyState = React.memo(({ selectedStatus }: VoteEmptyStateProps) => {
  const getMessage = () => {
    if (selectedStatus === VOTE_STATUS.ONGOING) {
      return '진행 중인 투표가 없습니다.';
    } else if (selectedStatus === VOTE_STATUS.UPCOMING) {
      return '예정된 투표가 없습니다.';
    } else {
      return '종료된 투표가 없습니다.';
    }
  };

  return (
    <div className='bg-gray-100 p-6 rounded-lg text-center'>
      <p className='text-gray-500'>{getMessage()}</p>
    </div>
  );
});

VoteEmptyState.displayName = 'VoteEmptyState';

export default VoteEmptyState; 