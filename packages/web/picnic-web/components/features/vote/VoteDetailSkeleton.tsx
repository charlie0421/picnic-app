import React from 'react';

const VoteDetailSkeleton: React.FC = () => {
  return (
    <div className='container mx-auto px-2 py-2'>
      {/* 상단 정보창 스켈레톤 */}
      <div className='sticky top-0 z-30 bg-gradient-to-r from-gray-200 to-gray-300 border-b px-2 py-6 min-h-[72px] md:py-6 md:min-h-[96px] flex flex-col items-start gap-y-1 relative animate-pulse'>
        <div className='h-6 bg-gray-300 rounded w-3/4 mb-2'></div>
        <div className='h-4 bg-gray-300 rounded w-1/2'></div>
        <div className='absolute right-2 top-4'>
          <div className='w-16 h-16 bg-gray-300 rounded-full'></div>
        </div>
      </div>

      {/* 상위 3위 스켈레톤 */}
      <div className='sticky top-[72px] md:top-[96px] z-20 bg-white border-b'>
        <div className='flex gap-3 overflow-x-auto px-1 py-3 justify-center'>
          {[...Array(3)].map((_, idx) => (
            <div key={idx} className='w-40 min-w-[10rem] flex-shrink-0'>
              <div className='bg-gray-100 rounded-xl overflow-hidden shadow-md animate-pulse h-[18.5rem]'>
                <div className='h-40 bg-gray-200'></div>
                <div className='p-3'>
                  <div className='h-5 bg-gray-200 rounded mb-2'></div>
                  <div className='h-4 bg-gray-200 rounded w-4/5 mb-2'></div>
                  <div className='h-8 bg-gray-200 rounded mt-4'></div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 리워드 섹션 스켈레톤 */}
      <div className='mt-4 p-3 bg-gray-100 rounded-lg animate-pulse'>
        <div className='h-6 bg-gray-200 rounded w-1/3 mb-3'></div>
        <div className='flex gap-2 overflow-x-auto'>
          {[...Array(3)].map((_, idx) => (
            <div
              key={idx}
              className='flex items-center bg-white rounded-lg p-2 shadow-sm border border-gray-200 w-full max-w-[200px]'
            >
              <div className='w-10 h-10 rounded bg-gray-200 mr-2'></div>
              <div className='flex-1'>
                <div className='h-4 bg-gray-200 rounded w-4/5'></div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 검색 필터 스켈레톤 */}
      <div className='mt-4 flex items-center gap-2 animate-pulse'>
        <div className='h-10 bg-gray-200 rounded flex-1'></div>
        <div className='h-10 w-24 bg-gray-200 rounded'></div>
      </div>

      {/* 투표 항목 그리드 스켈레톤 */}
      <div className='mt-4 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3'>
        {[...Array(12)].map((_, idx) => (
          <div
            key={idx}
            className='bg-gray-100 rounded-xl overflow-hidden shadow-md animate-pulse h-[180px]'
          >
            <div className='h-24 bg-gray-200'></div>
            <div className='p-3'>
              <div className='h-5 bg-gray-200 rounded mb-2'></div>
              <div className='h-4 bg-gray-200 rounded w-4/5'></div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default VoteDetailSkeleton;
