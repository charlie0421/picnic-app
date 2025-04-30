'use client';

import React, { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';
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
  }, [voteTotal, localVoteTotal]);

  // 부모 컴포넌트에 초기값 전달 (한 번만 실행)
  useEffect(() => {
    if (onVoteChange && localVoteTotal !== undefined) {
      onVoteChange(localVoteTotal);
    }
  }, []);

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

  // 총 가로폭 230px을 2:1.5:1 비율로 나눔
  const getCardWidth = (rankNum: number): number => {
    if (rankNum === 1) return 100; // 230 * (2/4.5) ≈ 102px, 반올림해서 100px
    if (rankNum === 2) return 75; // 230 * (1.5/4.5) ≈ 77px, 반올림해서 75px
    return 55; // 230 * (1/4.5) ≈ 51px, 반올림해서 55px
  };

  const cardWidth = getCardWidth(rank);

  return (
    <div
      className={`relative flex flex-col justify-between items-center p-0 rounded-xl backdrop-blur-sm transform transition-all duration-300 overflow-hidden self-end ${
        isAnimating ? 'animate-pulse' : ''
      } ${
        rank === 1
          ? 'h-[220px] bg-gradient-to-br from-yellow-50/30 to-yellow-100/30 border-2 border-yellow-200/50 order-2'
          : rank === 2
          ? 'h-[180px] bg-gradient-to-br from-gray-50/30 to-gray-100/30 border border-gray-200/50 order-1'
          : 'h-[160px] bg-gradient-to-br from-amber-50/30 to-amber-100/30 border border-amber-200/50 order-3'
      } ${className}`}
      style={{ width: `${cardWidth}px` }}
    >
      {/* 컨텐츠 컨테이너 */}
      <div className='flex flex-col justify-between w-full h-full'>
        {/* 상단 영역 - 랭크 태그 */}
        <div className='w-full flex justify-center mt-1'>
          <div
            className={`py-0.5 px-1.5 rounded-full text-xs font-bold shadow-lg flex items-center justify-center space-x-1 whitespace-nowrap ${
              RANK_BADGE_COLORS[rank - 1]
            }`}
          >
            <span className='text-sm'>{RANK_BADGE_ICONS[rank - 1]}</span>
            <span>{RANK_TEXTS[rank - 1]}</span>
          </div>
        </div>

        {/* 중앙 영역 - 이미지 */}
        <div className='flex flex-col w-full flex-1 justify-center items-center'>
          {/* 상단 공간 - 순위에 따라 다른 높이로 조정 */}
          <div
            style={{
              height: rank === 1 ? '0px' : rank === 2 ? '10px' : '20px',
            }}
          ></div>

          {/* 아티스트 이미지 */}
          <div
            className='rounded-full overflow-hidden border-4 border-yellow-200/50 shadow-lg'
            style={{
              width: `${cardWidth}px`,
              height: `${cardWidth}px`,
            }}
          >
            {item.artist && item.artist.image ? (
              <Image
                src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                alt={getLocalizedString(item.artist.name)}
                width={cardWidth}
                height={cardWidth}
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

        {/* 하단 정보 - 고정 위치 */}
        <div className='w-full text-center mb-2'>
          <div
            className={`font-bold min-h-[14px] flex items-center justify-center overflow-hidden min-w-0 max-w-full ${
              rank === 1
                ? 'text-xs text-yellow-700/70'
                : 'text-[10px] text-gray-700/70'
            }`}
          >
            <span className='truncate overflow-ellipsis max-w-full'>
              {item.artist
                ? getLocalizedString(item.artist.name) || '알 수 없는 아티스트'
                : '알 수 없는 아티스트'}
            </span>
          </div>
          <div className='min-h-[12px] flex items-center justify-center overflow-hidden min-w-0 max-w-full'>
            {item.artist?.artist_group ? (
              <span className='text-[9px] text-gray-600 truncate overflow-ellipsis max-w-full'>
                {getLocalizedString(item.artist.artist_group.name)}
              </span>
            ) : (
              <span className='text-[9px] text-transparent select-none'>-</span>
            )}
          </div>
          <div className='min-h-[14px] flex items-center justify-center font-bold overflow-hidden min-w-0 max-w-full'>
            <div className='relative w-full flex items-center justify-center'>
              {shouldShowVoteChange && (
                <div
                  className={`absolute -top-5 left-1/2 -translate-x-1/2 min-w-[24px] px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap z-10 ${
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
                    ? 'text-xs text-yellow-600/70'
                    : rank === 2
                    ? 'text-[10px] text-amber-600/70'
                    : 'text-[11px] text-amber-600/70 font-bold'
                }
              >
                {localVoteTotal.toLocaleString()}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VoteRankCard;
