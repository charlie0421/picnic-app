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
  const itemsPerPage = 8; // 한 페이지당 2줄 x 4개
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
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {currentItems.map((item) => (
        <div key={item.id} className="relative aspect-square">
          <Image
            src={getCdnImageUrl(getLocalizedString(item.artist?.image), 300)}
            alt={getLocalizedString(item.artist?.name)}
            fill
            sizes="(max-width: 768px) 50vw, 25vw"
            className="object-cover rounded-lg"
          />
        </div>
      ))}
    </div>
  );
};

export default UpcomingVoteItems; 