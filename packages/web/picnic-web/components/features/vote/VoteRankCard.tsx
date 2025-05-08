'use client';

import React, { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/strings';
import { useLanguageStore } from '@/stores/languageStore';

interface VoteRankCardProps {
  item: VoteItem & { artist?: any };
  rank: number;
  className?: string;
  showVoteChange?: boolean;
  voteChange?: number;
  voteTotal?: number;
  onVoteChange?: (voteTotal: number) => void;
  isAnimating?: boolean;
}

const VoteRankCard: React.FC<VoteRankCardProps> = ({
  item,
  rank,
  className = '',
  showVoteChange = false,
  voteChange = 0,
  voteTotal,
  onVoteChange,
  isAnimating = false,
}) => {
  const { t } = useLanguageStore();
  // 외부에서 제공된 voteTotal 값 사용 또는 기본값
  const initialVoteTotal =
    voteTotal !== undefined ? voteTotal : item.voteTotal ?? 0;
  const [localVoteTotal, setLocalVoteTotal] = useState(initialVoteTotal);

  // 애니메이션 관련 상태
  const [currentVoteChange, setCurrentVoteChange] = useState(voteChange);
  const processedVoteTotals = useRef<Set<number>>(new Set([initialVoteTotal]));
  const prevVoteTotal = useRef(initialVoteTotal);
  const animationTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // 컴포넌트 마운트 시 초기화
  useEffect(() => {
    return () => {
      // 컴포넌트 언마운트 시 모든 타이머 정리
      if (animationTimeoutRef.current) {
        clearTimeout(animationTimeoutRef.current);
      }
    };
  }, []);

  // 외부에서 voteChange가 제공되었을 때 업데이트
  useEffect(() => {
    if (voteChange !== 0) {
      setCurrentVoteChange(voteChange);
    }
  }, [voteChange]);

  // 투표수 변경 감지 - 애니메이션 중복 방지 강화
  useEffect(() => {
    // voteTotal이 없거나 이미 처리된 값이면 무시
    if (voteTotal === undefined || processedVoteTotals.current.has(voteTotal)) {
      return;
    }

    // 실제 투표수 변경이 있는 경우에만 처리
    if (voteTotal !== localVoteTotal) {
      // 변화량 계산
      const calculatedChange = voteTotal - prevVoteTotal.current;
      console.log(
        `VoteRankCard: 투표수 변경 - ${prevVoteTotal.current} -> ${voteTotal} (변화량: ${calculatedChange})`,
      );

      // 기존 애니메이션 타이머 정리
      if (animationTimeoutRef.current) {
        clearTimeout(animationTimeoutRef.current);
      }

      // 새로운 투표수 저장
      processedVoteTotals.current.add(voteTotal);
      prevVoteTotal.current = voteTotal;

      // 상태 업데이트 및 애니메이션 활성화
      setLocalVoteTotal(voteTotal);
      setCurrentVoteChange(calculatedChange);

      // 1초 후 애니메이션 종료
      animationTimeoutRef.current = setTimeout(() => {
        animationTimeoutRef.current = null;
      }, 1000);
    }
  }, [voteTotal,localVoteTotal]);

  // 부모 컴포넌트에 초기값 전달 (한 번만 실행)
  useEffect(() => {
    if (onVoteChange && localVoteTotal !== undefined) {
      onVoteChange(localVoteTotal);
    }
  }, [localVoteTotal, onVoteChange]);

  // 투표수 변화가 있고 애니메이션 중일 때만 변화량 표시
  const shouldShowVoteChange =
    isAnimating && currentVoteChange !== 0 && showVoteChange;

  const RANK_BADGE_COLORS = [
    'bg-gradient-to-br from-yellow-400/70 to-yellow-600/70 shadow-lg',
    'bg-gradient-to-br from-gray-300/70 to-gray-400/70 shadow-md',
    'bg-gradient-to-br from-amber-500/70 to-amber-700/70 shadow-sm',
  ];

  const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];
  const RANK_TEXTS = ['1st', '2nd', '3rd'];

  // 2:1.5:1 비율에 따른 카드 클래스 결정
  const getCardWidthClass = (rankNum: number): string => {
    if (rankNum === 1) return 'w-[44%]'; // 2/4.5 ≈ 44%
    if (rankNum === 2) return 'w-[33%]'; // 1.5/4.5 ≈ 33%
    return 'w-[23%]'; // 1/4.5 ≈ 23%
  };

  // className에 너비 클래스가 포함되어 있으면 기본 너비 클래스를 사용하지 않음
  const hasWidthClass = className.includes('w-');
  const cardWidthClass = hasWidthClass ? '' : getCardWidthClass(rank);

  return (
    <div
      className={`relative flex flex-col justify-between items-center p-0 rounded-xl backdrop-blur-sm transform transition-all duration-300 overflow-hidden self-end ${
        isAnimating ? 'animate-pulse' : ''
      } ${
        rank === 1
          ? 'bg-gradient-to-br from-yellow-50/30 to-yellow-100/30 border-2 border-yellow-200/50 order-2'
          : rank === 2
          ? 'bg-gradient-to-br from-gray-50/30 to-gray-100/30 border border-gray-200/50 order-1'
          : 'bg-gradient-to-br from-amber-50/30 to-amber-100/30 border border-amber-200/50 order-3'
      } ${cardWidthClass} ${className}`}
    >
      {/* 컨텐츠 컨테이너 */}
      <div className='flex flex-col justify-between w-full h-full'>
        {/* 상단 영역 - 랭크 태그 */}
        <div className='w-full flex justify-center pt-2 pb-1'>
          <div
            className={`py-1 px-2.5 rounded-full text-xs font-bold shadow-lg flex items-center justify-center space-x-1 whitespace-nowrap ${
              RANK_BADGE_COLORS[rank - 1]
            }`}
          >
            <span className='text-sm'>{RANK_BADGE_ICONS[rank - 1]}</span>
            <span>{RANK_TEXTS[rank - 1]}</span>
          </div>
        </div>

        {/* 이미지 영역 */}
        <div className='w-full mx-auto mt-1 mb-2 px-1'>
          <div className='aspect-square relative'>
            <div className='absolute inset-0 rounded-full overflow-hidden border-4 border-yellow-200/50 shadow-lg'>
              {item.artist && item.artist.image ? (
                <Image
                  src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                  alt={getLocalizedString(item.artist.name)}
                  width={100}
                  height={100}
                  className='w-full h-full object-cover'
                  priority
                />
              ) : (
                <div className='w-full h-full bg-gray-200/50 flex items-center justify-center'>
                  <span className='text-gray-400 text-xs'>이미지 없음</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 하단 정보 */}
        <div className='w-full text-center mb-2 px-1 flex-1 flex flex-col justify-center'>
          <div className='flex flex-col space-y-1'>
            <div
              className={`font-bold flex items-center justify-center overflow-hidden min-w-0 max-w-full ${
                rank === 1
                  ? 'text-sm text-yellow-700/70'
                  : 'text-xs text-gray-700/70'
              }`}
            >
              <span className='truncate overflow-ellipsis max-w-full'>
                {item.artist
                  ? getLocalizedString(item.artist.name) || '알 수 없는 아티스트'
                  : '알 수 없는 아티스트'}
              </span>
            </div>
            <div className='flex items-center justify-center overflow-hidden min-w-0 max-w-full'>
              {item.artist?.artist_group ? (
                <span className='text-[10px] text-gray-600 truncate overflow-ellipsis max-w-full'>
                  {getLocalizedString(item.artist.artist_group.name)}
                </span>
              ) : (
                <span className='text-[10px] text-transparent select-none'>-</span>
              )}
            </div>
            <div className='flex items-center justify-center font-bold overflow-hidden min-w-0 max-w-full'>
              <div className='relative w-full flex items-center justify-center'>
                {shouldShowVoteChange && (
                  <div
                    className={`absolute -top-4 left-1/2 -translate-x-1/2 min-w-[20px] px-1 py-0.5 rounded-full text-[10px] font-semibold whitespace-nowrap z-10 ${
                      currentVoteChange > 0
                        ? 'bg-green-200 text-green-800 border border-green-300'
                        : 'bg-red-200 text-red-800 border border-red-300'
                    } animate-bounce shadow-sm`}
                  >
                    {currentVoteChange > 0 ? '+' : ''}
                    {currentVoteChange}
                  </div>
                )}
                <span
                  className={
                    rank === 1
                      ? 'text-sm text-yellow-600/70'
                      : rank === 2
                      ? 'text-xs text-amber-600/70'
                      : 'text-xs text-amber-600/70 font-bold'
                  }
                >
                  {localVoteTotal.toLocaleString()}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VoteRankCard;
