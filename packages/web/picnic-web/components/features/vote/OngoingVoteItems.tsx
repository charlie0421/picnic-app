'use client';

import React, { useEffect, useRef, useState, useMemo } from 'react';
import Image from 'next/image';
import { Vote, VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';
import VoteRankCard from './VoteRankCard';
import { getVoteItems } from '@/utils/api/queries';

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400 via-yellow-500 to-yellow-600 shadow-lg',
  'bg-gradient-to-br from-gray-300 via-gray-400 to-gray-500 shadow-md',
  'bg-gradient-to-br from-amber-500 via-amber-600 to-amber-700 shadow-sm',
];

const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];

const OngoingVoteItems: React.FC<{
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
  voteItems?: Array<VoteItem & { artist?: any }>;
}> = ({ vote, voteItems: externalVoteItems }) => {
  const { t } = useLanguageStore();
  const [isRankAnimating, setIsRankAnimating] = useState(false);
  const [prevRankings, setPrevRankings] = useState<Map<number, number>>(new Map());
  const [prevVotes, setPrevVotes] = useState<Map<number, number>>(new Map());
  const [voteChanges, setVoteChanges] = useState<Map<number, number>>(new Map());
  const voteTimerRef = useRef<NodeJS.Timeout | null>(null);
  const rankTimerRef = useRef<NodeJS.Timeout | null>(null);
  const [currentVoteItems, setCurrentVoteItems] = useState(externalVoteItems || vote.voteItems || []);
  const isFirstUpdate = useRef(true);
  const lastUpdateTime = useRef<number>(Date.now());
  const isUpdating = useRef(false);
  const prevVoteTotals = useRef<Map<number, number>>(new Map());

  // 초기 prevVoteTotals 설정
  useEffect(() => {
    if (currentVoteItems.length > 0) {
      const newPrevVoteTotals = new Map<number, number>();
      currentVoteItems.forEach(item => {
        newPrevVoteTotals.set(item.id, item.voteTotal || 0);
      });
      prevVoteTotals.current = newPrevVoteTotals;
    }
  }, []);

  // 외부 voteItems가 변경되면 currentVoteItems 업데이트
  useEffect(() => {
    if (externalVoteItems) {
      const now = Date.now();
      // 첫 번째 업데이트는 증감 이벤트를 발생시키지 않음
      if (isFirstUpdate.current) {
        isFirstUpdate.current = false;
        setCurrentVoteItems(externalVoteItems);
        // prevVoteTotals 업데이트
        externalVoteItems.forEach(item => {
          prevVoteTotals.current.set(item.id, item.voteTotal || 0);
        });
        lastUpdateTime.current = now;
        return;
      }

      // 마지막 업데이트로부터 1초가 지났는지 확인
      if (now - lastUpdateTime.current >= 1000) {
        // 투표수 변경 감지
        const newVoteChanges = new Map<number, number>();
        externalVoteItems.forEach(item => {
          const prevTotal = prevVoteTotals.current.get(item.id) || 0;
          const currentTotal = item.voteTotal || 0;
          if (prevTotal !== currentTotal) {
            newVoteChanges.set(item.id, currentTotal - prevTotal);
            prevVoteTotals.current.set(item.id, currentTotal);
          }
        });

        if (newVoteChanges.size > 0) {
          setVoteChanges(newVoteChanges);
          // 1초 후에 증감 표시 제거
          if (voteTimerRef.current) {
            clearTimeout(voteTimerRef.current);
          }
          voteTimerRef.current = setTimeout(() => {
            setVoteChanges(new Map());
            voteTimerRef.current = null;
          }, 1000);
        }

        setCurrentVoteItems(externalVoteItems);
        lastUpdateTime.current = now;
      }
    }
  }, [externalVoteItems]);

  // 1초마다 투표수 업데이트 (externalVoteItems가 없을 때만 실행)
  useEffect(() => {
    if (externalVoteItems) return;

    const updateVoteItems = async () => {
      if (isUpdating.current) return;

      try {
        isUpdating.current = true;
        const updatedItems = await getVoteItems(vote.id);
        if (updatedItems) {
          const now = Date.now();
          // 마지막 업데이트로부터 1초가 지났는지 확인
          if (now - lastUpdateTime.current >= 1000) {
            // 투표수 변경 감지
            const newVoteChanges = new Map<number, number>();
            updatedItems.forEach(item => {
              const prevTotal = prevVoteTotals.current.get(item.id) || 0;
              const currentTotal = item.voteTotal || 0;
              if (prevTotal !== currentTotal) {
                newVoteChanges.set(item.id, currentTotal - prevTotal);
                prevVoteTotals.current.set(item.id, currentTotal);
              }
            });

            if (newVoteChanges.size > 0) {
              setVoteChanges(newVoteChanges);
              // 1초 후에 증감 표시 제거
              if (voteTimerRef.current) {
                clearTimeout(voteTimerRef.current);
              }
              voteTimerRef.current = setTimeout(() => {
                setVoteChanges(new Map());
                voteTimerRef.current = null;
              }, 1000);
            }

            setCurrentVoteItems(updatedItems);
            lastUpdateTime.current = now;
          }
        }
      } catch (error) {
        console.error('투표수 업데이트 중 오류가 발생했습니다:', error);
      } finally {
        isUpdating.current = false;
      }
    };

    const intervalId = setInterval(updateVoteItems, 1000);
    return () => {
      clearInterval(intervalId);
      if (voteTimerRef.current) {
        clearTimeout(voteTimerRef.current);
      }
    };
  }, [vote.id, externalVoteItems]);

  const topThreeItems = useMemo(() => {
    if (!currentVoteItems || currentVoteItems.length === 0) {
      return [];
    }
    return [...currentVoteItems]
      .sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0))
      .slice(0, 3);
  }, [currentVoteItems]);

  // 순위 변경 감지
  useEffect(() => {
    const currentRankings = new Map(topThreeItems.map((item, index) => [item.id, index + 1]));
    let hasRankChange = false;

    // 순위 변경 감지
    currentRankings.forEach((rank, id) => {
      const prevRank = prevRankings.get(id) || rank;
      if (rank !== prevRank) {
        hasRankChange = true;
      }
    });

    if (hasRankChange) {
      setIsRankAnimating(true);
      setPrevRankings(currentRankings);
      
      if (rankTimerRef.current) {
        clearTimeout(rankTimerRef.current);
      }
      rankTimerRef.current = setTimeout(() => {
        setIsRankAnimating(false);
        rankTimerRef.current = null;
      }, 1000);
    }

    // 초기 상태 설정
    if (prevRankings.size === 0) {
      setPrevRankings(currentRankings);
    }

    return () => {
      if (rankTimerRef.current) {
        clearTimeout(rankTimerRef.current);
      }
    };
  }, [topThreeItems]);

  // 투표수 변경 표시 조건
  const shouldShowVoteChange = (itemId: number) => {
    return voteChanges.has(itemId);
  };

  if (!currentVoteItems || currentVoteItems.length === 0 || topThreeItems.length === 0) {
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
              isAnimating={isRankAnimating}
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