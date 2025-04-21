'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { VoteItem } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

const UpcomingVoteItems: React.FC<{
  voteItems?: Array<VoteItem & { artist?: any }>;
}> = ({ voteItems }) => {
  const [currentPage, setCurrentPage] = useState(0);
  const itemsPerPage = 8; // 한 페이지당 2줄 x 4개
  const totalPages = Math.ceil((voteItems?.length || 0) / itemsPerPage);

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

  const currentItems = voteItems?.slice(
    currentPage * itemsPerPage,
    (currentPage + 1) * itemsPerPage
  );

  return (
    <div className="relative">
      <div className="overflow-hidden">
        <div className="grid grid-cols-4 grid-rows-2 gap-4 p-4">
          {currentItems?.map((item, index) => (
            <div key={index} className="flex flex-col items-center">
              <div className="w-16 h-16 relative rounded-full overflow-hidden border-2 border-blue-200">
                {item.artist?.image && (
                  <Image
                    src={getCdnImageUrl(item.artist.image)}
                    alt={getLocalizedString(item.artist.name)}
                    fill
                    className="object-cover"
                  />
                )}
              </div>
              <div className="mt-2 text-center">
                <div className="text-xs font-medium text-gray-700 truncate max-w-[80px]">
                  {getLocalizedString(item.artist?.name) || '알 수 없는 아티스트'}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
      
      {totalPages > 1 && (
        <div 
          className="flex justify-center items-center space-x-2 mt-2"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
          }}
        >
          <button
            onClick={handlePrevPage}
            disabled={currentPage === 0}
            className={`p-2 rounded-full bg-white shadow-md ${
              currentPage === 0
                ? 'text-gray-500 cursor-not-allowed'
                : 'text-blue-500 hover:bg-blue-50'
            }`}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                clipRule="evenodd"
              />
            </svg>
          </button>
          <span className="text-xs text-gray-600 bg-white px-3 py-2 rounded-full shadow-md">
            {currentPage + 1} / {totalPages}
          </span>
          <button
            onClick={handleNextPage}
            disabled={currentPage === totalPages - 1}
            className={`p-2 rounded-full bg-white shadow-md ${
              currentPage === totalPages - 1
                ? 'text-gray-500 cursor-not-allowed'
                : 'text-blue-500 hover:bg-blue-50'
            }`}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clipRule="evenodd"
              />
            </svg>
          </button>
        </div>
      )}
    </div>
  );
};

export default UpcomingVoteItems; 