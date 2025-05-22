import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { useLanguageStore } from '@/stores/languageStore';
import CountdownTimer from '@/components/features/CountdownTimer';
import { getLocalizedString } from '@/utils/api/strings';
import RewardItem from '@/components/common/RewardItem';
import VoteItems from '../VoteItems';

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];

const STATUS_TAG_COLORS: Record<VoteStatus, string> = {
  [VOTE_STATUS.UPCOMING]: 'bg-blue-500 text-white border border-blue-600',
  [VOTE_STATUS.ONGOING]: 'bg-green-500 text-white border border-green-600',
  [VOTE_STATUS.COMPLETED]: 'bg-gray-500 text-white border border-gray-600',
};

// 카테고리별 색상
const CATEGORY_COLORS = {
  birthday: 'bg-pink-100 text-pink-800 border border-pink-200',
  debut: 'bg-blue-100 text-blue-800 border border-blue-200',
  accumulated: 'bg-purple-100 text-purple-800 border border-purple-200',
  special: 'bg-indigo-100 text-indigo-800 border border-indigo-200',
  event: 'bg-orange-100 text-orange-800 border border-orange-200',
} as const;

// 서브카테고리별 색상
const SUB_CATEGORY_COLORS = {
  male: 'bg-blue-50 text-blue-600 border border-blue-100',
  female: 'bg-pink-50 text-pink-600 border border-pink-100',
  group: 'bg-green-50 text-green-600 border border-green-100',
  all: 'bg-gray-50 text-gray-600 border border-gray-100',
} as const;

const getStatusText = (
  status: VoteStatus,
  t: (key: string) => string,
): string => {
  switch (status) {
    case VOTE_STATUS.UPCOMING:
      return t('label_tabbar_vote_upcoming');
    case VOTE_STATUS.ONGOING:
      return t('label_tabbar_vote_active');
    case VOTE_STATUS.COMPLETED:
      return t('label_tabbar_vote_end');
    default:
      return '';
  }
};

const VoteCard = React.memo(
  ({ vote, onClick }: { vote: Vote; onClick?: () => void }) => {
    const { t } = useLanguageStore();
    const now = useRef(new Date());
    const status = useMemo(() => {
      if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
      const start = new Date(vote.startAt);
      const end = new Date(vote.stopAt);
      if (now.current < start) return VOTE_STATUS.UPCOMING;
      if (now.current > end) return VOTE_STATUS.COMPLETED;
      return VOTE_STATUS.ONGOING;
    }, [vote.startAt, vote.stopAt]);

    // 1초마다 현재 시간 업데이트
    useEffect(() => {
      const timer = setInterval(() => {
        now.current = new Date();
      }, 1000);

      return () => clearInterval(timer);
    }, []);

    return (
      <Link href={`/vote/${vote.id}`}>
        <div className='bg-gradient-to-br from-white to-gray-50 rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 h-full flex flex-col'>
          <div className='relative'>
            {vote.mainImage && (
              <div className='h-48 sm:h-56 md:h-64 bg-gray-200 relative'>
                <Image
                  src={getCdnImageUrl(vote.mainImage)}
                  alt={getLocalizedString(vote.title)}
                  width={320}
                  height={256}
                  className='w-full h-full object-cover'
                  priority
                />
                <div className='absolute inset-0 bg-gradient-to-t from-black/60 to-transparent' />
              </div>
            )}
          </div>

          <div className='p-1 sm:p-2 flex-1 flex flex-col'>
            <div className='flex flex-wrap gap-0.5 mb-1'>
              {vote.voteCategory && (
                <span
                  className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ${
                    CATEGORY_COLORS[
                      vote.voteCategory as keyof typeof CATEGORY_COLORS
                    ] || 'bg-gray-100 text-gray-800 border border-gray-200'
                  }`}
                >
                  {t(`label_vote_${vote.voteCategory}`)}
                </span>
              )}
              {vote.voteSubCategory && (
                <span
                  className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ${
                    SUB_CATEGORY_COLORS[
                      vote.voteSubCategory as keyof typeof SUB_CATEGORY_COLORS
                    ] || 'bg-gray-50 text-gray-600 border border-gray-100'
                  }`}
                >
                  {t(`compatibility_gender_${vote.voteSubCategory}`)}
                </span>
              )}
              <span
                className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ml-auto ${STATUS_TAG_COLORS[status]}`}
              >
                {getStatusText(status, t)}
              </span>
            </div>

            <h3 className='font-extrabold text-base sm:text-lg mb-4 text-gray-900 truncate p-2 relative group'>
              {getLocalizedString(vote.title)}
              <span className='absolute bottom-0 left-2 right-2 h-[2px] bg-primary/30 group-hover:bg-primary/50 transition-colors duration-300'></span>
            </h3>

            <div className='flex justify-center mb-4'>
              <CountdownTimer
                startTime={vote.startAt}
                endTime={vote.stopAt}
                status={
                  status === VOTE_STATUS.UPCOMING
                    ? 'scheduled'
                    : status === VOTE_STATUS.COMPLETED
                    ? 'ended'
                    : 'in_progress'
                }
              />
            </div>

            <div className='flex-1'>
              <VoteItems vote={vote} />
            </div>

            {vote.voteReward && vote.voteReward.length > 0 && (
              <div className='mt-2 bg-yellow-50 rounded-lg p-3 border border-yellow-100'>
                <div className='flex items-center text-yellow-700 font-medium mb-2'>
                  <svg
                    xmlns='http://www.w3.org/2000/svg'
                    className='h-5 w-5 mr-1'
                    viewBox='0 0 20 20'
                    fill='currentColor'
                  >
                    <path
                      fillRule='evenodd'
                      d='M5 5a3 3 0 015-2.236A3 3 0 0114.83 6H16a2 2 0 110 4h-5V9a1 1 0 10-2 0v1H4a2 2 0 110-4h1.17C5.06 5.687 5 5.35 5 5zm4 1V5a1 1 0 10-1 1h1zm3 0a1 1 0 10-1-1v1h1z'
                      clipRule='evenodd'
                    />
                    <path d='M9 11H3v5a2 2 0 002 2h4v-7zM11 18h4a2 2 0 002-2v-5h-6v7z' />
                  </svg>
                  <span className='text-sm sm:text-base'>
                    {t('text_vote_reward', {
                      count: vote.voteReward.length.toString(),
                    })}
                  </span>
                </div>
                <div className='flex flex-wrap gap-2'>
                  {vote.voteReward.slice(0, 2).map((reward) => (
                    <RewardItem key={reward.reward?.id} reward={reward.reward!} />
                  ))}
                  {vote.voteReward.length > 2 && (
                    <div className='w-full text-center'>
                      <span className='text-xs text-gray-500'>
                        +{vote.voteReward.length - 2}개 더보기
                      </span>
                    </div>
                  )}
                </div>
              </div>
            )}

            <div className='mt-1 pt-2 border-t border-gray-100'>
              {vote.startAt && vote.stopAt && (
                <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between text-sm gap-1 sm:gap-0'>
                  <div className='flex items-center space-x-2 bg-primary/5 rounded-lg px-3 py-2'>
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-4 w-4 text-primary'
                      viewBox='0 0 20 20'
                      fill='currentColor'
                    >
                      <path
                        fillRule='evenodd'
                        d='M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z'
                        clipRule='evenodd'
                      />
                    </svg>
                    <span className='text-primary font-medium'>
                      {format(new Date(vote.startAt), 'MM.dd HH:mm', {
                        locale: ko,
                      })}{' '}
                      ~{' '}
                      {format(new Date(vote.stopAt), 'MM.dd HH:mm', {
                        locale: ko,
                      })}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </Link>
    );
  },
);

VoteCard.displayName = 'VoteCard';

export default VoteCard; 