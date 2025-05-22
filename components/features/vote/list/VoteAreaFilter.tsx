import React from 'react';

const VOTE_AREAS = {
  KPOP: 'kpop',
  MUSICAL: 'musical',
} as const;

type VoteArea = (typeof VOTE_AREAS)[keyof typeof VOTE_AREAS];

interface VoteAreaFilterProps {
  selectedArea: VoteArea;
  onAreaChange: (area: VoteArea) => void;
}

const VoteAreaFilter = React.memo(
  ({ selectedArea, onAreaChange }: VoteAreaFilterProps) => {
    return (
      <div className='flex flex-wrap justify-start gap-1 sm:gap-1.5 bg-white/50 backdrop-blur-sm p-1.5 rounded-lg shadow-sm border border-gray-100'>
        <button
          onClick={() => onAreaChange(VOTE_AREAS.KPOP)}
          className={`px-1.5 py-0.5 sm:px-2.5 sm:py-1 rounded-lg text-[10px] sm:text-xs font-medium transition-all duration-200 ${
            selectedArea === VOTE_AREAS.KPOP
              ? 'bg-primary text-white shadow-sm transform scale-[1.02]'
              : 'bg-gray-50 text-gray-600 hover:bg-primary/10 hover:text-primary hover:shadow-sm'
          }`}
        >
          K-POP
        </button>
        <button
          onClick={() => onAreaChange(VOTE_AREAS.MUSICAL)}
          className={`px-1.5 py-0.5 sm:px-2.5 sm:py-1 rounded-lg text-[10px] sm:text-xs font-medium transition-all duration-200 ${
            selectedArea === VOTE_AREAS.MUSICAL
              ? 'bg-primary text-white shadow-sm transform scale-[1.02]'
              : 'bg-gray-50 text-gray-600 hover:bg-primary/10 hover:text-primary hover:shadow-sm'
          }`}
        >
          K-MUSICAL
        </button>
      </div>
    );
  },
);

VoteAreaFilter.displayName = 'VoteAreaFilter';

export default VoteAreaFilter; 