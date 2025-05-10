import React from 'react';
import { Vote } from '@/types/interfaces';
import VoteCard from './VoteCard';
import VoteLoadingSkeleton from './VoteLoadingSkeleton';
import VoteEmptyState from './VoteEmptyState';
import { useVoteFilterStore } from '@/stores/voteFilterStore';

interface VoteListSectionProps {
  votes: Vote[];
  isLoading: boolean;
  isTransitioning: boolean;
  onVoteClick: (voteId: string) => void;
}

const VoteListSection: React.FC<VoteListSectionProps> = ({
  votes,
  isLoading,
  isTransitioning,
  onVoteClick,
}) => {
  const { selectedStatus } = useVoteFilterStore();

  if (isLoading && votes.length === 0) {
    return <VoteLoadingSkeleton />;
  }

  if (votes.length === 0) {
    return (
      <div className='bg-gray-100 p-6 rounded-lg text-center'>
        <p className='text-gray-500'>투표가 없습니다.</p>
      </div>
    );
  }

  return (
    <div className={`transition-all duration-300 ${isTransitioning ? 'opacity-50' : 'opacity-100'}`}>
      {votes.length === 0 ? (
        <VoteEmptyState selectedStatus={selectedStatus} />
      ) : (
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6 md:gap-8'>
          {votes.map((vote) => (
            <VoteCard
              key={vote.id}
              vote={vote}
              onClick={() => onVoteClick(vote.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default VoteListSection; 