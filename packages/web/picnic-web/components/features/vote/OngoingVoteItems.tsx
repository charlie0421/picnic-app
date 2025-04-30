'use client';

import React, { useEffect, useState } from 'react';
import { Vote, VoteItem } from '@/types/interfaces';
import { useLanguageStore } from '@/stores/languageStore';
import VoteRankCard from './VoteRankCard';

// 확장된 VoteItem 타입 정의
interface EnhancedVoteItem extends VoteItem {
  artist?: any;
  isAnimating?: boolean;
  voteChange?: number;
}

interface OngoingVoteItemsProps {
  vote: Vote & { voteItems?: EnhancedVoteItem[] };
  onVoteChange?: (
    voteId: string | number,
    itemId: string | number,
    newTotal: number,
  ) => void;
}

const OngoingVoteItems: React.FC<OngoingVoteItemsProps> = ({
  vote,
  onVoteChange,
}) => {
  const { t } = useLanguageStore();
  const [voteItems, setVoteItems] = useState<EnhancedVoteItem[]>(
    vote.voteItems || [],
  );

  // vote.voteItems가 변경될 때마다 로컬 상태 업데이트
  useEffect(() => {
    if (vote.voteItems) {
      console.log('OngoingVoteItems: voteItems 업데이트됨', vote.voteItems);
      setVoteItems(vote.voteItems);
    }
  }, [vote.voteItems]);

  // 투표수 변경 감지 및 처리
  const handleVoteChange = (itemId: string | number, newTotal: number) => {
    console.log(`OngoingVoteItems: 투표수 변경 (${itemId}) - ${newTotal}`);
    // 로컬 상태 업데이트
    setVoteItems((prevItems) =>
      prevItems.map((item) =>
        item.id === itemId ? { ...item, voteTotal: newTotal } : item,
      ),
    );

    // 부모 컴포넌트에 변경 알림
    if (onVoteChange) {
      onVoteChange(vote.id, itemId, newTotal);
    }
  };

  // 상위 3개 항목만 필터링
  const topItems = [...voteItems]
    .sort((a, b) => (b.voteTotal ?? 0) - (a.voteTotal ?? 0))
    .slice(0, 3);

  return (
    <div className='w-full'>
      <div className='flex justify-center items-end space-x-1'>
        {topItems.map((item, index) => (
          <VoteRankCard
            key={item.id}
            item={item}
            rank={index + 1}
            showVoteChange={true}
            isAnimating={item.isAnimating}
            voteChange={item.voteChange}
            voteTotal={item.voteTotal ?? undefined}
            onVoteChange={(newTotal) => handleVoteChange(item.id, newTotal)}
          />
        ))}
      </div>
    </div>
  );
};

export default OngoingVoteItems;
