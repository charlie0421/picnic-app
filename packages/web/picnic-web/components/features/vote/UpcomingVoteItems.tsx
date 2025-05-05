'use client';

import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import { VoteItem } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

const UpcomingVoteItems: React.FC<{
  voteItems?: Array<VoteItem & { artist?: any }>;
}> = ({ voteItems }) => {
  const [currentPage, setCurrentPage] = useState(0);
  const [shuffledItems, setShuffledItems] = useState<Array<VoteItem & { artist?: any }>>([]);
  const [mounted, setMounted] = useState(false);
  const itemsPerPage = 12; // 한 페이지당 3줄 x 4개
  const totalPages = Math.ceil((voteItems?.length || 0) / itemsPerPage);

  useEffect(() => {
    setMounted(true);
  }, []);

  // 투표아이템을 랜덤으로 섞는 함수
  const shuffleItems = (items: Array<VoteItem & { artist?: any }>) => {
    const shuffled = [...items];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  };

  // 컴포넌트가 마운트된 후에만 랜덤으로 섞기
  useEffect(() => {
    if (mounted && voteItems && voteItems.length > 0) {
      setShuffledItems(shuffleItems(voteItems));
    }
  }, [mounted, voteItems]);

  const handlePrevPage = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setCurrentPage((prev) => Math.max(0, prev - 1));
  };

  const handleNextPage = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setCurrentPage((prev) => Math.min(totalPages - 1, prev + 1));
  };

  const currentItems = mounted ? shuffledItems.slice(
    currentPage * itemsPerPage,
    (currentPage + 1) * itemsPerPage
  ) : voteItems?.slice(0, itemsPerPage) || [];

  if (!voteItems || voteItems.length === 0) {
    return null;
  }

  return (
    <div className="flex flex-col">
      <div className="grid grid-cols-4 md:grid-cols-4 gap-1">
        {currentItems.map((item) => (
          <div key={item.id} className="relative aspect-square">
            <div className="w-full h-full rounded-full overflow-hidden">
              <Image
                src={getCdnImageUrl(item.artist?.image, 300)}
                alt={getLocalizedString(item.artist?.name)}
                fill
                sizes="(max-width: 768px) 50vw, 25vw"
                className="object-cover"
              />
            </div>
            <div className="absolute bottom-0 left-0 right-0 text-center mt-1">
              <p className="text-gray-800 text-xs font-medium truncate bg-white/80 rounded-full py-1 px-1 mx-1">
                {getLocalizedString(item.artist?.name)}
              </p>
            </div>
          </div>
        ))}
      </div>
      
      {totalPages > 1 && (
        <div className="flex justify-center items-center my-2 py-1 gap-2">
          <button
            onClick={handlePrevPage}
            disabled={currentPage === 0}
            className="p-2 rounded-full bg-gray-100 text-gray-600 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-200"
            aria-label="이전 페이지"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          
          <span className="text-sm text-gray-500">
            {currentPage + 1} / {totalPages}
          </span>
          
          <button
            onClick={handleNextPage}
            disabled={currentPage === totalPages - 1}
            className="p-2 rounded-full bg-gray-100 text-gray-600 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-200"
            aria-label="다음 페이지"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      )}
    </div>
  );
};

export default UpcomingVoteItems; 