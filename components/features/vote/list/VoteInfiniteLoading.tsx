import React from 'react';

const VoteInfiniteLoading = React.memo(() => (
  <div className='w-full flex flex-col items-center justify-center py-4'>
    <div className='relative w-8 h-8'>
      <div className='absolute top-0 left-0 w-full h-full border-2 border-primary/20 rounded-full'></div>
      <div className='absolute top-0 left-0 w-full h-full border-2 border-primary border-t-transparent rounded-full animate-spin'></div>
    </div>
  </div>
));

VoteInfiniteLoading.displayName = 'VoteInfiniteLoading';

export default VoteInfiniteLoading; 