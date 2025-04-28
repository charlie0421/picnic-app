'use client';

import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import { VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';
import { getVoteItems } from '@/utils/api/queries';
import { useLanguageStore } from '@/stores/languageStore';

interface VoteRankCardProps {
  item: VoteItem & { artist?: any };
  rank: number;
  className?: string;
  showVoteChange?: boolean;
  isAnimating?: boolean;
  voteChange?: number;
}

const VoteRankCard: React.FC<VoteRankCardProps> = ({
  item,
  rank,
  className = '',
  showVoteChange = false,
  isAnimating = false,
  voteChange = 0,
}) => {
  const { t } = useLanguageStore();
  const [prevVoteTotal, setPrevVoteTotal] = useState(item.voteTotal || 0);

  // 1초마다 투표수 확인
  useEffect(() => {
    if (!showVoteChange || !item.voteId) return;

    const checkVoteChanges = async () => {
      try {
        const voteItemsData = await getVoteItems(item.voteId || 0);
        const currentItem = voteItemsData.find((v) => v.id === item.id);
        const currentVoteTotal = currentItem?.voteTotal || 0;

        if (currentVoteTotal !== prevVoteTotal) {
          setPrevVoteTotal(currentVoteTotal);
        }
      } catch (error) {
        console.error('투표수 확인 중 오류가 발생했습니다:', error);
      }
    };

    const intervalId = setInterval(checkVoteChanges, 1000);
    return () => clearInterval(intervalId);
  }, [item.id, item.voteId, prevVoteTotal, showVoteChange]);

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
            } ${isAnimating ? 'animate-rank-pulse' : ''}`}
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
              {showVoteChange && voteChange !== 0 && (
                <div
                  className={`absolute -top-3 left-1/2 -translate-x-1/2 px-1 py-0.5 rounded-full text-[9px] font-medium whitespace-nowrap ${
                    voteChange > 0
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-700'
                  } animate-fade-in-out`}
                >
                  {voteChange > 0 ? '+' : ''}
                  {voteChange}
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
                {item.voteTotal?.toLocaleString() || 0}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VoteRankCard;
