'use client';

import React, { useEffect, useRef, useState, useMemo } from 'react';
import Image from 'next/image';
import { Vote, VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';
import VoteRankCard from './VoteRankCard';

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400 via-yellow-500 to-yellow-600 shadow-lg',
  'bg-gradient-to-br from-gray-300 via-gray-400 to-gray-500 shadow-md',
  'bg-gradient-to-br from-amber-500 via-amber-600 to-amber-700 shadow-sm',
];

const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];

const OngoingVoteItems: React.FC<{
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
}> = ({ vote }) => {
  const { t } = useLanguageStore();
  const [isRankAnimating, setIsRankAnimating] = useState(false);
  const [isVoteAnimating, setIsVoteAnimating] = useState(false);
  const [prevRankings, setPrevRankings] = useState<Map<number, number>>(new Map());
  const [prevVotes, setPrevVotes] = useState<Map<number, number>>(new Map());
  const [voteChanges, setVoteChanges] = useState<Map<number, number>>(new Map());

  // 이전 아이템 데이터를 저장하는 ref
  const prevItemsRef = useRef<Map<number, { rank: number; voteTotal: number }>>(
    new Map(),
  );

  // 변경사항 감지 및 애니메이션 상태
  const [animations, setAnimations] = useState<
    Map<
      number,
      {
        rankChanged: boolean;
        voteChanged: boolean;
        increased: boolean;
        prevRank: number;
      }
    >
  >(new Map());

  const topThreeItems = useMemo(() => {
    if (!vote.voteItems || vote.voteItems.length === 0) {
      return [];
    }
    return [...vote.voteItems]
      .sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0))
      .slice(0, 3);
  }, [vote.voteItems]);

  // 순위 및 투표수 변경 감지
  useEffect(() => {
    const currentRankings = new Map(topThreeItems.map((item, index) => [item.id, index + 1]));
    const currentVotes = new Map(topThreeItems.map(item => [item.id, item.voteTotal || 0]));
    const newVoteChanges = new Map<number, number>();
    let hasRankChange = false;
    let hasVoteChange = false;

    // 투표수 변경 감지
    currentVotes.forEach((votes, id) => {
      const prevVote = prevVotes.get(id) || votes;
      if (votes !== prevVote) {
        hasVoteChange = true;
        newVoteChanges.set(id, votes - prevVote);
      }
    });

    // 순위 변경 감지
    currentRankings.forEach((rank, id) => {
      const prevRank = prevRankings.get(id) || rank;
      if (rank !== prevRank) {
        hasRankChange = true;
      }
    });

    // 상태 업데이트
    if (hasVoteChange) {
      setIsVoteAnimating(true);
      setPrevVotes(currentVotes);
      setVoteChanges(newVoteChanges);
      
      const voteTimer = setTimeout(() => {
        setIsVoteAnimating(false);
        setVoteChanges(new Map());
      }, 1000);
      
      return () => {
        clearTimeout(voteTimer);
        setIsVoteAnimating(false);
        setVoteChanges(new Map());
      };
    }

    if (hasRankChange) {
      setIsRankAnimating(true);
      setPrevRankings(currentRankings);
      
      const rankTimer = setTimeout(() => {
        setIsRankAnimating(false);
      }, 1000);
      
      return () => {
        clearTimeout(rankTimer);
        setIsRankAnimating(false);
      };
    }

    // 초기 상태 설정
    if (prevVotes.size === 0) {
      setPrevVotes(currentVotes);
    }
    if (prevRankings.size === 0) {
      setPrevRankings(currentRankings);
    }
  }, [topThreeItems]);

  // 투표수 변경 표시 조건 수정
  const shouldShowVoteChange = (itemId: number) => {
    return isVoteAnimating && voteChanges.has(itemId);
  };

  if (!vote.voteItems || vote.voteItems.length === 0 || topThreeItems.length === 0) {
    return null;
  }

  return (
    <div className='mt-4'>
      <div className='relative'>
        {/* 배경 디자인 요소 */}
        <div className='absolute inset-0 bg-gradient-to-br from-white to-gray-100 rounded-xl'></div>

        <div className='relative grid grid-cols-1 sm:grid-cols-3 items-center gap-4 py-3 mt-8'>
          {topThreeItems.map((item, index) => (
            <VoteRankCard
              key={item.id}
              item={item}
              rank={index + 1}
              isAnimating={isRankAnimating || isVoteAnimating}
              voteChange={voteChanges.get(item.id) || 0}
              showVoteChange={shouldShowVoteChange(item.id)}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default OngoingVoteItems; 