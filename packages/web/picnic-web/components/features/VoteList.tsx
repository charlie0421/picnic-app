'use client';

import React, { useEffect, useState, useMemo, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';
import { format, differenceInDays, differenceInSeconds } from 'date-fns';
import { ko } from 'date-fns/locale';
import { getVotes } from '@/utils/api/queries';
import UpcomingVoteItems from './vote/UpcomingVoteItems';
import OngoingVoteItems from './vote/OngoingVoteItems';
import CompletedVoteItems from './vote/CompletedVoteItems';

interface VoteListProps {
  votes: Vote[];
}

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

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400 to-yellow-600 shadow-lg',
  'bg-gradient-to-br from-gray-300 to-gray-400 shadow-md',
  'bg-gradient-to-br from-amber-500 to-amber-700 shadow-sm',
];

const RANK_BADGE_ICONS = ['👑', '🥈', '🥉'];

// 카테고리 매핑
const VOTE_CATEGORIES = {
  birthday: '생일투표',
  debut: '데뷔투표',
  accumulated: '누적투표',
  special: '스페셜투표',
  event: '이벤트투표',
} as const;

// 서브카테고리 매핑
const VOTE_SUB_CATEGORIES = {
  male: '남자',
  female: '여자',
  group: '그룹',
  all: '전체',
} as const;

// 카테고리별 아이콘 (SVG 경로)
const CATEGORY_ICONS = {
  birthday: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M6 3.75A2.75 2.75 0 018.75 1h2.5A2.75 2.75 0 0114 3.75v.443c.795.077 1.584.24 2.346.485a.75.75 0 01.154 1.384A9.958 9.958 0 0010 18a9.958 9.958 0 00-6.5-2.388.75.75 0 01.154-1.384A13.718 13.718 0 016 4.193V3.75zm2.75-.75A1.25 1.25 0 008.75 2.5h2.5A1.25 1.25 0 0012.5 3.75V4c0 .092.002.184.005.274a.75.75 0 01-.83.853 15.99 15.99 0 00-3.35 0 .75.75 0 01-.83-.853A8.032 8.032 0 018.75 4v-.25z'
        clipRule='evenodd'
      />
    </svg>
  ),
  debut: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path d='M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118l-2.8-2.034c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z' />
    </svg>
  ),
  accumulated: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M12 7a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0V8.414l-4.293 4.293a1 1 0 01-1.414 0L8 10.414l-4.293 4.293a1 1 0 01-1.414-1.414l5-5a1 1 0 011.414 0L11 10.586 14.586 7H12z'
        clipRule='evenodd'
      />
    </svg>
  ),
  special: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path d='M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z' />
    </svg>
  ),
  event: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z'
        clipRule='evenodd'
      />
    </svg>
  ),
};

// 상태별 아이콘
const STATUS_ICONS = {
  [VOTE_STATUS.UPCOMING]: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z'
        clipRule='evenodd'
      />
    </svg>
  ),
  [VOTE_STATUS.ONGOING]: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z'
        clipRule='evenodd'
      />
    </svg>
  ),
  [VOTE_STATUS.COMPLETED]: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z'
        clipRule='evenodd'
      />
    </svg>
  ),
};

// 서브카테고리별 아이콘
const SUB_CATEGORY_ICONS = {
  male: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z'
        clipRule='evenodd'
      />
    </svg>
  ),
  female: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path
        fillRule='evenodd'
        d='M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 102 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z'
        clipRule='evenodd'
      />
    </svg>
  ),
  group: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path d='M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z' />
    </svg>
  ),
  all: (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      className='h-3 w-3 mr-1'
      viewBox='0 0 20 20'
      fill='currentColor'
    >
      <path d='M7 3a1 1 0 000 2h6a1 1 0 100-2H7zM4 7a1 1 0 011-1h10a1 1 0 110 2H5a1 1 0 01-1-1zM2 11a2 2 0 012-2h12a2 2 0 012 2v4a2 2 0 01-2 2H4a2 2 0 01-2-2v-4z' />
    </svg>
  ),
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

// CountdownTimer 컴포넌트 분리
const CountdownTimer = React.memo(({ vote }: { vote: Vote }) => {
  const [remainingTime, setRemainingTime] = useState<{
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
  } | null>(null);
  const [isUpdating, setIsUpdating] = useState(false);

  const { targetDate, label } = useMemo(() => {
    const now = new Date();
    const startDate = vote.startAt ? new Date(vote.startAt) : null;
    const endDate = vote.stopAt ? new Date(vote.stopAt) : null;

    if (startDate && now < startDate) {
      return { targetDate: startDate, label: '시작까지' };
    } else if (endDate && now < endDate) {
      return { targetDate: endDate, label: '종료까지' };
    }
    return { targetDate: null, label: '' };
  }, [vote.startAt, vote.stopAt]);

  useEffect(() => {
    if (!targetDate) return;

    const calculateRemainingTime = () => {
      const now = new Date();
      const diffInSeconds = differenceInSeconds(targetDate, now);

      if (diffInSeconds <= 0) {
        setRemainingTime(null);
        return;
      }

      const days = Math.floor(diffInSeconds / 86400);
      const hours = Math.floor((diffInSeconds % 86400) / 3600);
      const minutes = Math.floor((diffInSeconds % 3600) / 60);
      const seconds = diffInSeconds % 60;

      setRemainingTime({ days, hours, minutes, seconds });
    };

    calculateRemainingTime();
    const timer = setInterval(calculateRemainingTime, 1000);
    const animationInterval = setInterval(() => setIsUpdating(prev => !prev), 500);

    return () => {
      clearInterval(timer);
      clearInterval(animationInterval);
    };
  }, [targetDate]);

  if (!remainingTime) return null;

  return (
    <div className='flex flex-col items-center'>
      <div className='text-xs text-gray-500 mb-1'>{label}</div>
      <div className='flex space-x-1'>
        {Object.entries(remainingTime).map(([unit, value]) => (
          <div key={unit} className='flex flex-col items-center'>
            <div
              className={`bg-primary/10 w-10 h-10 rounded-md flex items-center justify-center font-mono font-bold text-primary ${
                isUpdating ? 'text-opacity-80' : 'text-opacity-100'
              } transition-all`}
            >
              {value.toString().padStart(2, '0')}
            </div>
            <div className='text-[10px] text-gray-500 mt-1'>
              {unit === 'days' ? '일' : unit === 'hours' ? '시' : unit === 'minutes' ? '분' : '초'}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
});

CountdownTimer.displayName = 'CountdownTimer';

// RewardItem 컴포넌트 분리
const RewardItem = React.memo(({ reward }: { reward: Reward }) => (
  <div className='flex items-center bg-white rounded-lg p-2 shadow-sm border border-yellow-200 w-full'>
    {reward.thumbnail ? (
      <div className='w-10 h-10 rounded overflow-hidden mr-2'>
        <Image
          src={getCdnImageUrl(reward.thumbnail)}
          alt={getLocalizedString(reward.title) || '리워드'}
          width={40}
          height={40}
          className='w-full h-full object-cover'
        />
      </div>
    ) : (
      <div className='w-10 h-10 rounded overflow-hidden mr-2 bg-yellow-100 flex items-center justify-center'>
        <svg
          xmlns='http://www.w3.org/2000/svg'
          className='h-5 w-5 text-yellow-400'
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
      </div>
    )}
    <div className="flex-1 min-w-0">
      <div className="text-sm font-medium text-gray-900 truncate">
        {getLocalizedString(reward.title) || '리워드 정보'}
      </div>
    </div>
  </div>
));

RewardItem.displayName = 'RewardItem';

// VoteItems 컴포넌트 분리
const VoteItems = React.memo(({ vote }: { vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> } }) => {
  const status = useMemo(() => {
    if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
    const now = new Date();
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    if (now < start) return VOTE_STATUS.UPCOMING;
    if (now > end) return VOTE_STATUS.COMPLETED;
    return VOTE_STATUS.ONGOING;
  }, [vote.startAt, vote.stopAt]);

  switch (status) {
    case VOTE_STATUS.UPCOMING:
      return <UpcomingVoteItems voteItems={vote.voteItems} />;
    case VOTE_STATUS.ONGOING:
      return <OngoingVoteItems vote={vote} />;
    case VOTE_STATUS.COMPLETED:
      return <CompletedVoteItems vote={vote} />;
    default:
      return null;
  }
});

VoteItems.displayName = 'VoteItems';

// VoteCard 컴포넌트 분리
const VoteCard = React.memo(({ vote }: { vote: Vote }) => {
  const status = useMemo(() => {
    if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
    const now = new Date();
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    if (now < start) return VOTE_STATUS.UPCOMING;
    if (now > end) return VOTE_STATUS.COMPLETED;
    return VOTE_STATUS.ONGOING;
  }, [vote.startAt, vote.stopAt]);

  const periodText = useMemo(() => {
    if (!vote.startAt || !vote.stopAt) return '기간 미정';
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    const now = new Date();

    if (now < start) {
      const daysUntilStart = differenceInDays(start, now);
      return `${daysUntilStart}일 후 시작`;
    }
    if (now > end) return '투표 종료';
    const daysLeft = differenceInDays(end, now);
    return `${daysLeft}일 남음`;
  }, [vote.startAt, vote.stopAt]);

  return (
    <Link href={`/vote/${vote.id}`}>
      <div className='bg-gradient-to-br from-white to-gray-50 rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100'>
        <div className='absolute top-3 right-3 z-10 flex flex-wrap gap-1 justify-end max-w-[75%]'>
          <span
            className={`flex items-center px-3 py-1.5 rounded-full text-sm font-bold ${
              STATUS_TAG_COLORS[status]
            }`}
          >
            {getStatusText(status)}
          </span>
        </div>

        <div className='relative'>
          {vote.mainImage && (
            <div className='h-48 bg-gray-200 relative'>
              <Image
                src={getCdnImageUrl(vote.mainImage)}
                alt={vote.title}
                width={320}
                height={192}
                className='w-full h-full object-cover'
                priority
              />
              <div className='absolute inset-0 bg-gradient-to-t from-black/60 to-transparent' />
            </div>
          )}
        </div>

        <div className='p-5'>
          <div className='flex flex-wrap gap-1 mb-3'>
            {vote.voteCategory && (
              <span
                className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm ${
                  CATEGORY_COLORS[vote.voteCategory as keyof typeof CATEGORY_COLORS] ||
                  'bg-gray-100 text-gray-800 border border-gray-200'
                }`}
              >
                {VOTE_CATEGORIES[vote.voteCategory as keyof typeof VOTE_CATEGORIES] || vote.voteCategory}
              </span>
            )}
            {vote.voteSubCategory && (
              <span
                className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm ${
                  SUB_CATEGORY_COLORS[vote.voteSubCategory as keyof typeof SUB_CATEGORY_COLORS] ||
                  'bg-gray-50 text-gray-600 border border-gray-100'
                }`}
              >
                {VOTE_SUB_CATEGORIES[vote.voteSubCategory as keyof typeof VOTE_SUB_CATEGORIES] || vote.voteSubCategory}
              </span>
            )}
          </div>

          <h3 className='font-bold text-lg mb-3 text-gray-800 line-clamp-2'>
            {getLocalizedString(vote.title)}
          </h3>

          <div className='flex justify-center mb-4'>
            <CountdownTimer vote={vote} />
          </div>

          <VoteItems vote={vote} />

          {vote.rewards && vote.rewards.length > 0 && (
            <div className='mt-4 bg-yellow-50 rounded-lg p-3 border border-yellow-100'>
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
                리워드 {vote.rewards.length}개
              </div>
              <div className='flex flex-wrap gap-2'>
                {vote.rewards.slice(0, 2).map((reward) => (
                  <RewardItem key={reward.id} reward={reward} />
                ))}
                {vote.rewards.length > 2 && (
                  <div className="w-full text-center">
                    <span className='text-xs text-gray-500'>
                      +{vote.rewards.length - 2}개 더보기
                    </span>
                  </div>
                )}
              </div>
            </div>
          )}

          <div className='mt-4 pt-4 border-t border-gray-100'>
            {vote.startAt && vote.stopAt && (
              <div className='flex items-center justify-between text-sm'>
                <span className='text-gray-500 font-medium'>
                  {periodText}
                </span>
                <span className='text-primary/70'>
                  {format(new Date(vote.startAt), 'MM.dd', { locale: ko })} ~{' '}
                  {format(new Date(vote.stopAt), 'MM.dd', { locale: ko })}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>
    </Link>
  );
});

VoteCard.displayName = 'VoteCard';

const getStatusText = (status: VoteStatus): string => {
  switch (status) {
    case VOTE_STATUS.UPCOMING:
      return '예정됨';
    case VOTE_STATUS.ONGOING:
      return '진행 중';
    case VOTE_STATUS.COMPLETED:
      return '종료됨';
    default:
      return '';
  }
};

const VoteList: React.FC = () => {
  const [mounted, setMounted] = useState(false);
  const [votes, setVotes] = useState<Vote[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<VoteStatus | 'all'>('all');

  const updateVoteData = useCallback(async () => {
    try {
      setLoading(true);
      const votesData = await getVotes('votes');
      setVotes(votesData);
    } catch (error) {
      console.error('투표 데이터를 가져오는 중 오류가 발생했습니다:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    setMounted(true);
    updateVoteData();

    let timer: NodeJS.Timeout | null = null;
    if (selectedStatus === VOTE_STATUS.ONGOING || selectedStatus === 'all') {
      timer = setInterval(updateVoteData, 1000);
    }

    return () => {
      if (timer) clearInterval(timer);
    };
  }, [selectedStatus, updateVoteData]);

  const filteredVotes = useMemo(() => {
    if (selectedStatus === 'all') return votes;
    return votes.filter((vote) => {
      if (!vote.startAt || !vote.stopAt) return selectedStatus === VOTE_STATUS.UPCOMING;
      const now = new Date();
      const start = new Date(vote.startAt);
      const end = new Date(vote.stopAt);
      if (selectedStatus === VOTE_STATUS.UPCOMING) return now < start;
      if (selectedStatus === VOTE_STATUS.ONGOING) return now >= start && now <= end;
      return now > end;
    });
  }, [votes, selectedStatus]);

  if (!mounted) return null;

  return (
    <section>
      <div className='flex justify-between items-center mb-6'>
        <div className='flex space-x-1 bg-gray-100 p-1 rounded-lg shadow-sm'>
          <button
            onClick={() => setSelectedStatus('all')}
            className={`px-4 py-2 text-sm font-medium rounded-md transition-all ${
              selectedStatus === 'all'
                ? 'bg-white text-primary shadow-sm'
                : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
            }`}
          >
            전체
          </button>
          <button
            onClick={() => setSelectedStatus(VOTE_STATUS.ONGOING)}
            className={`px-4 py-2 text-sm font-medium rounded-md flex items-center transition-all ${
              selectedStatus === VOTE_STATUS.ONGOING
                ? 'bg-white text-green-600 shadow-sm'
                : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
            }`}
          >
            진행 중
          </button>
          <button
            onClick={() => setSelectedStatus(VOTE_STATUS.UPCOMING)}
            className={`px-4 py-2 text-sm font-medium rounded-md flex items-center transition-all ${
              selectedStatus === VOTE_STATUS.UPCOMING
                ? 'bg-white text-blue-600 shadow-sm'
                : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
            }`}
          >
            예정됨
          </button>
          <button
            onClick={() => setSelectedStatus(VOTE_STATUS.COMPLETED)}
            className={`px-4 py-2 text-sm font-medium rounded-md flex items-center transition-all ${
              selectedStatus === VOTE_STATUS.COMPLETED
                ? 'bg-white text-gray-600 shadow-sm'
                : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
            }`}
          >
            종료됨
          </button>
        </div>
      </div>

      {loading && votes.length === 0 ? (
        <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className='bg-white rounded-xl shadow-md overflow-hidden border border-gray-100 animate-pulse'
            >
              <div className='h-48 bg-gray-200'></div>
              <div className='p-5'>
                <div className='flex space-x-2 mb-3'>
                  <div className='h-4 bg-gray-200 rounded-full w-20'></div>
                  <div className='h-4 bg-gray-200 rounded-full w-16'></div>
                </div>
                <div className='h-6 bg-gray-200 rounded w-3/4 mb-4'></div>
                <div className='flex justify-center mb-4'>
                  <div className='h-12 bg-gray-200 rounded w-40'></div>
                </div>
                <div className='h-24 bg-gray-200 rounded-xl mb-4'></div>
                <div className='h-10 bg-gray-100 rounded-lg mt-4'></div>
                <div className='h-4 bg-gray-200 rounded w-full mt-4'></div>
              </div>
            </div>
          ))}
        </div>
      ) : votes.length === 0 ? (
        <div className='bg-gray-100 p-6 rounded-lg text-center'>
          <p className='text-gray-500'>투표가 없습니다.</p>
        </div>
      ) : filteredVotes.length === 0 ? (
        <div className='bg-gray-100 p-6 rounded-lg text-center'>
          <p className='text-gray-500'>
            {selectedStatus === VOTE_STATUS.ONGOING
              ? '진행 중인 투표가 없습니다.'
              : selectedStatus === VOTE_STATUS.UPCOMING
              ? '예정된 투표가 없습니다.'
              : '종료된 투표가 없습니다.'}
          </p>
        </div>
      ) : (
        <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
          {filteredVotes.slice(0, 6).map((vote) => (
            <VoteCard key={vote.id} vote={vote} />
          ))}
        </div>
      )}
    </section>
  );
};

export default VoteList;
