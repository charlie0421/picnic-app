import React from 'react';

const VoteLoadingSkeleton = React.memo(() => (
  <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
    {[1, 2, 3, 4].map((i) => (
      <div
        key={i}
        className='bg-white rounded-xl shadow-md overflow-hidden border border-gray-100 animate-pulse'
      >
        <div className='h-48 bg-gray-200'></div>
        <div className='p-5'>
          <div className='flex space-x-2 mb-3'>
            <div className='h-4 bg-gray-200 rounded-full w-20'></div>
            <div className='h-4 bg-gray-200 rounded-full w-16'></div>
          </div>
          <div className='h-6 bg-gray-200 rounded w-3/4 mb-4'></div>
          <div className='flex justify-center mb-4'>
            <div className='h-12 bg-gray-200 rounded w-40'></div>
          </div>
          <div className='h-24 bg-gray-200 rounded-xl mb-4'></div>
          <div className='h-10 bg-gray-100 rounded-lg mt-4'></div>
          <div className='h-4 bg-gray-200 rounded w-full mt-4'></div>
        </div>
      </div>
    ))}
  </div>
));

VoteLoadingSkeleton.displayName = 'VoteLoadingSkeleton';

export default VoteLoadingSkeleton; 