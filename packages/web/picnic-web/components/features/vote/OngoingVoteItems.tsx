'use client';

import React, { useEffect, useRef, useState, useMemo } from 'react';
import Image from 'next/image';
import { Vote, VoteItem } from '@/types/interfaces';
import { getLocalizedString } from '@/utils/api/image';
import { useLanguageStore } from '@/stores/languageStore';

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400 to-yellow-600 shadow-lg',
  'bg-gradient-to-br from-gray-300 to-gray-400 shadow-md',
  'bg-gradient-to-br from-amber-500 to-amber-700 shadow-sm',
];

const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];

const OngoingVoteItems: React.FC<{
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
}> = ({ vote }) => {
  const { t } = useLanguageStore();
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

  // 변경 감지 효과
  useEffect(() => {
    if (topThreeItems.length === 0) return;

    const newAnimations = new Map();

    topThreeItems.forEach((item, index) => {
      const itemId = item.id;
      const currentRank = index + 1;
      const currentVotes = item.voteTotal || 0;

      // 이전 데이터가 있는지 확인
      if (prevItemsRef.current.has(itemId)) {
        const prevData = prevItemsRef.current.get(itemId)!;

        // 순위나 투표 수 변경 감지
        const rankChanged = prevData.rank !== currentRank;
        const voteChanged = prevData.voteTotal !== currentVotes;
        const increased = currentVotes > prevData.voteTotal;

        if (rankChanged || voteChanged) {
          newAnimations.set(itemId, {
            rankChanged,
            voteChanged,
            increased,
            prevRank: prevData.rank,
          });

          // 1.5초 후 애니메이션 상태 제거
          setTimeout(() => {
            setAnimations((prev) => {
              const updated = new Map(prev);
              updated.delete(itemId);
              return updated;
            });
          }, 1500);
        }
      }

      // 현재 데이터 저장
      prevItemsRef.current.set(itemId, {
        rank: currentRank,
        voteTotal: currentVotes,
      });
    });

    if (newAnimations.size > 0) {
      setAnimations(newAnimations);
    }
  }, [topThreeItems]);

  if (!vote.voteItems || vote.voteItems.length === 0 || topThreeItems.length === 0) {
    return null;
  }

  return (
    <div className='mt-4'>
      <div className='relative'>
        {/* 배경 디자인 요소 */}
        <div className='absolute inset-0 bg-gradient-to-br from-white to-gray-100 rounded-xl'></div>

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

            // 애니메이션 상태 가져오기
            const animation = animations.get(item.id);
            const hasAnimation = !!animation;

            // 순위 변경 애니메이션 클래스
            let rankChangeClass = '';
            if (animation?.rankChanged) {
              if (animation.prevRank > index + 1) {
                // 순위 상승
                rankChangeClass = 'animate-bounce-up text-green-600';
              } else {
                // 순위 하락
                rankChangeClass = 'animate-bounce-down text-red-600';
              }
            }

            // 투표수 변경 애니메이션 클래스
            let voteChangeClass = '';
            if (animation?.voteChanged) {
              voteChangeClass = animation.increased
                ? 'animate-pulse text-green-600 font-extrabold scale-110'
                : 'animate-pulse text-red-600 font-extrabold';
            }

            return (
              <div
                key={item.id}
                className={`w-full ${order} ${scale} transform transition-all duration-300 hover:scale-105 ${
                  hasAnimation ? 'ring-2 ring-primary ring-opacity-50' : ''
                }`}
              >
                <div
                  className={`relative flex flex-col items-center p-3 rounded-xl backdrop-blur-sm 
                  ${
                    index === 0
                      ? 'bg-gradient-to-br from-yellow-50 to-yellow-100 border-2 border-yellow-300 shadow-xl'
                      : index === 1
                      ? 'bg-gradient-to-br from-gray-50 to-gray-100 border border-gray-300 shadow-md'
                      : 'bg-gradient-to-br from-amber-50 to-amber-100 border border-amber-300 shadow-md'
                  }`}
                >
                  {/* 순위 뱃지 */}
                  <div
                    className={`absolute -top-4 left-1/2 transform -translate-x-1/2 py-1 ${
                      t('text_vote_rank', {'rank': '1'}).length > 3 ? 'px-3' : 'px-2'
                    } rounded-full ${
                      RANK_BADGE_COLORS[index]
                    } text-white font-bold shadow-lg flex items-center justify-center space-x-1 whitespace-nowrap ${rankChangeClass}`}
                  >
                    <span className='text-lg'>{RANK_BADGE_ICONS[index]}</span>
                    <span className='text-[10px]'>{t('text_vote_rank', {'rank': (index + 1).toString()} )}</span>

                    {/* 순위 변동 표시 */}
                    {animation?.rankChanged && (
                      <span
                        className={`ml-1 text-xs ${
                          animation.prevRank > index + 1
                            ? 'text-green-100'
                            : 'text-red-100'
                        }`}
                      >
                        {animation.prevRank > index + 1 ? (
                          <svg
                            xmlns='http://www.w3.org/2000/svg'
                            className='h-3 w-3 inline'
                            viewBox='0 0 20 20'
                            fill='currentColor'
                          >
                            <path
                              fillRule='evenodd'
                              d='M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z'
                              clipRule='evenodd'
                            />
                          </svg>
                        ) : (
                          <svg
                            xmlns='http://www.w3.org/2000/svg'
                            className='h-3 w-3 inline'
                            viewBox='0 0 20 20'
                            fill='currentColor'
                          >
                            <path
                              fillRule='evenodd'
                              d='M16.707 10.293a1 1 0 010 1.414l-6 6a1 1 0 01-1.414 0l-6-6a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l4.293-4.293a1 1 0 011.414 0z'
                              clipRule='evenodd'
                            />
                          </svg>
                        )}
                        {Math.abs(animation.prevRank - (index + 1))}
                      </span>
                    )}
                  </div>

                  {/* 아티스트 이미지 */}
                  <div
                    className={`w-16 h-16 rounded-full overflow-hidden border-4 ${
                      index === 0
                        ? 'border-yellow-300 w-20 h-20'
                        : index === 1
                        ? 'border-gray-300'
                        : 'border-amber-300'
                    } shadow-lg mt-4 ${
                      hasAnimation ? 'animate-pulse-light' : ''
                    }`}
                  >
                    {item.artist && item.artist.image ? (
                      <Image
                        src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                        alt={getLocalizedString(item.artist.name)}
                        width={index === 0 ? 80 : 64}
                        height={index === 0 ? 80 : 64}
                        className='w-full h-full object-cover'
                        priority
                      />
                    ) : (
                      <div className='w-full h-full bg-gray-200 flex items-center justify-center'>
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
                          ? 'text-lg text-yellow-700'
                          : index === 1
                          ? 'text-base text-gray-700'
                          : 'text-base text-amber-700'
                      } truncate max-w-[150px]`}
                    >
                      {item.artist ? getLocalizedString(item.artist.name) || '알 수 없는 아티스트' : '알 수 없는 아티스트'}
                    </div>
                    {item.artist?.artist_group && (
                      <div className='text-xs text-gray-600 mt-1'>
                        {getLocalizedString(item.artist.artist_group.name)}
                      </div>
                    )}
                    <div
                      className={`mt-2 font-bold ${
                        index === 0
                          ? 'text-lg text-yellow-600'
                          : index === 1
                          ? 'text-base text-gray-600'
                          : 'text-base text-amber-600'
                      } ${voteChangeClass}`}
                    >
                      {item.voteTotal?.toLocaleString() || 0}{' '}
                      {/* 투표수 변동 표시 */}
                      {animation?.voteChanged && (
                        <span
                          className={`ml-1 text-xs ${
                            animation.increased
                              ? 'text-green-600'
                              : 'text-red-600'
                          }`}
                        >
                          {animation.increased ? '+' : '-'}
                        </span>
                      )}
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

export default OngoingVoteItems; 