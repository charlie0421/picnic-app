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

  return (
    <div
      className={`relative flex flex-col justify-between items-center p-0.5 rounded-xl backdrop-blur-sm transform transition-all duration-300 overflow-hidden self-end ${
        isAnimating ? 'animate-pulse' : ''
      } ${
        rank === 1
          ? 'flex-[2_1_0%] h-[260px] bg-gradient-to-br from-yellow-50/30 to-yellow-100/30 border-2 border-yellow-200/50 order-2'
          : rank === 2
          ? 'flex-[1.5_1_0%] h-[220px] bg-gradient-to-br from-gray-50/30 to-gray-100/30 border border-gray-200/50 order-1'
          : 'flex-[1_1_0%] h-[200px] bg-gradient-to-br from-amber-50/30 to-amber-100/30 border border-amber-200/50 order-3'
      } ${className}`}
    >
      {/* 상단(랭크 태그 + 이미지) */}
      <div>
        {/* 순위 뱃지 - 카드 내부 상단에 flex로 배치 */}
        <div className='w-full flex justify-center mb-1'>
          <div
            className={`py-0.5 px-1.5 rounded-full text-xs font-bold shadow-lg flex items-center justify-center space-x-1 whitespace-nowrap ${
              RANK_BADGE_COLORS[rank - 1]
            } ${isAnimating ? 'animate-rank-pulse' : ''}`}
          >
            <span className='text-sm'>{RANK_BADGE_ICONS[rank - 1]}</span>
            <span>{t('text_vote_rank', { rank: rank.toString() })}</span>
          </div>
        </div>
        {/* 아티스트 이미지 */}
        <div
          className='rounded-full overflow-hidden border-4 w-[100px] h-[100px] max-w-[100px] max-h-[100px] border-yellow-200/50 shadow-lg mx-auto'
        >
          {item.artist && item.artist.image ? (
            <Image
              src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
              alt={getLocalizedString(item.artist.name)}
              width={100}
              height={100}
              className='w-full h-full object-cover max-w-full max-h-full'
              priority
            />
          ) : (
            <div className='w-full h-full bg-gray-200/50 flex items-center justify-center'>
              <span className='text-gray-400 text-xs'>이미지 없음</span>
            </div>
          )}
        </div>
      </div>
      {/* 하단 정보 */}
      <div className="w-full text-center mt-auto">
        <div
          className={`font-bold ${
            rank === 1
              ? 'text-sm text-yellow-700/70'
              : rank === 2
              ? 'text-xs text-gray-700/70'
              : 'text-xs text-amber-700/70'
          } truncate max-w-[150px]`}
        >
          {item.artist ? getLocalizedString(item.artist.name) || '알 수 없는 아티스트' : '알 수 없는 아티스트'}
        </div>
        {item.artist?.artist_group && (
          <div className='text-xs text-gray-600 mt-1 truncate max-w-[150px]'>
            {getLocalizedString(item.artist.artist_group.name)}
          </div>
        )}
        <div className='mt-2 flex flex-col items-center'>
          <div className='relative'>
            {showVoteChange && voteChange !== 0 && (
              <div
                className={`absolute -top-4 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-full text-xs font-medium whitespace-nowrap ${
                  voteChange > 0 
                    ? 'bg-green-100 text-green-700' 
                    : 'bg-red-100 text-red-700'
                } animate-fade-in-out`}
              >
                {voteChange > 0 ? '+' : ''}{voteChange}
              </div>
            )}
            <div
              className={`font-bold ${
                rank === 1
                  ? 'text-sm text-yellow-600/70'
                  : rank === 2
                  ? 'text-xs text-gray-600/70'
                  : 'text-xs text-amber-600/70'
              }`}
            >
              {item.voteTotal?.toLocaleString() || 0}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VoteRankCard; 