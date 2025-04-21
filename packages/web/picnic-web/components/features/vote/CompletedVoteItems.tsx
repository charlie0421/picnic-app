'use client';

import React from 'react';
import Image from 'next/image';
import { Vote, VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400/70 to-yellow-600/70 shadow-lg',
  'bg-gradient-to-br from-gray-300/70 to-gray-400/70 shadow-md',
  'bg-gradient-to-br from-amber-500/70 to-amber-700/70 shadow-sm',
];

const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];

const CompletedVoteItems: React.FC<{
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
}> = ({ vote }) => {
  if (!vote.voteItems || vote.voteItems.length === 0) {
    return null;
  }

  const topThreeItems = [...vote.voteItems]
    .sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0))
    .slice(0, 3);

  if (topThreeItems.length === 0) {
    return null;
  }

  return (
    <div className='mt-4'>
      <div className='relative'>
        {/* 배경 디자인 요소 - 더 어둡고 과거의 느낌을 주는 그라데이션 */}
        <div className='absolute inset-0 bg-gradient-to-br from-gray-100/30 to-gray-200/30 rounded-xl opacity-50'></div>

        <div className='relative flex flex-col md:flex-row items-center justify-around gap-2 py-3'>
          {topThreeItems.map((item, index) => {
            // 1위는 중앙, 2위는 왼쪽, 3위는 오른쪽에 배치
            const order =
              index === 0
                ? 'md:order-2 z-10'
                : index === 1
                ? 'md:order-1 z-5'
                : 'md:order-3 z-5';
            const scale =
              index === 0 ? 'md:scale-110 -mt-2 md:mt-0' : 'md:scale-100';

            return (
              <div
                key={item.id}
                className={`w-full ${order} ${scale} transform transition-all duration-300`}
              >
                <div
                  className={`relative flex flex-col items-center p-3 rounded-xl backdrop-blur-sm 
                  ${
                    index === 0
                      ? 'bg-gradient-to-br from-yellow-50/30 to-yellow-100/30 border-2 border-yellow-200/50'
                      : index === 1
                      ? 'bg-gradient-to-br from-gray-50/30 to-gray-100/30 border border-gray-200/50'
                      : 'bg-gradient-to-br from-amber-50/30 to-amber-100/30 border border-amber-200/50'
                  }`}
                >
                  {/* 순위 뱃지 */}
                  <div
                    className={`absolute -top-4 ${
                      index === 0
                        ? 'left-1/2 transform -translate-x-1/2'
                        : index === 1
                        ? 'left-0'
                        : 'right-0'
                    } py-1 px-3 rounded-full ${
                      RANK_BADGE_COLORS[index]
                    } text-white/90 font-bold shadow-lg flex items-center justify-center space-x-1`}
                  >
                    <span className='text-xl'>{RANK_BADGE_ICONS[index]}</span>
                    <span className='text-sm'>{index + 1}위</span>
                  </div>

                  {/* 아티스트 이미지 */}
                  <div
                    className={`w-16 h-16 rounded-full overflow-hidden border-4 ${
                      index === 0
                        ? 'border-yellow-200/50 w-20 h-20'
                        : index === 1
                        ? 'border-gray-200/50'
                        : 'border-amber-200/50'
                    } shadow-lg mt-4`}
                  >
                    {item.artist && item.artist.image ? (
                      <Image
                        src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                        alt={getLocalizedString(item.artist.name) || '아티스트'}
                        width={index === 0 ? 80 : 64}
                        height={index === 0 ? 80 : 64}
                        className='w-full h-full object-cover grayscale opacity-80'
                        priority
                      />
                    ) : (
                      <div className='w-full h-full bg-gray-200/50 flex items-center justify-center'>
                        <span className='text-gray-400 text-xs'>
                          이미지 없음
                        </span>
                      </div>
                    )}
                  </div>

                  {/* 아티스트 정보 */}
                  <div className='mt-3 text-center'>
                    <div
                      className={`font-bold ${
                        index === 0
                          ? 'text-lg text-yellow-700/70'
                          : index === 1
                          ? 'text-base text-gray-700/70'
                          : 'text-base text-amber-700/70'
                      } truncate max-w-[150px]`}
                    >
                      {item.artist
                        ? getLocalizedString(item.artist.name) ||
                          '알 수 없는 아티스트'
                        : '알 수 없는 아티스트'}
                    </div>
                    {item.artist?.artist_group && (
                      <div className='text-xs text-gray-500/70 mt-1'>
                        {getLocalizedString(item.artist.artist_group.name) || ''}
                      </div>
                    )}
                    <div
                      className={`mt-2 font-bold ${
                        index === 0
                          ? 'text-lg text-yellow-600/70'
                          : index === 1
                          ? 'text-base text-gray-600/70'
                          : 'text-base text-amber-600/70'
                      }`}
                    >
                      {item.voteTotal?.toLocaleString() || 0}{' '}
                      <span className='text-sm font-normal'>표</span>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default CompletedVoteItems; 