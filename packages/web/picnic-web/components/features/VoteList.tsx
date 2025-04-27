'use client';

import React, { useEffect, useState, useMemo, useCallback, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';
import { format, differenceInDays, differenceInSeconds } from 'date-fns';
import { ko } from 'date-fns/locale';
import { getVotes } from '@/utils/api/queries';
import { useLanguageStore } from '@/stores/languageStore';
import UpcomingVoteItems from './vote/UpcomingVoteItems';
import OngoingVoteItems from './vote/OngoingVoteItems';
import CompletedVoteItems from './vote/CompletedVoteItems';
import CountdownTimer from '@/components/features/CountdownTimer';

interface VoteListProps {
  votes: Vote[];
  pageSize?: number;
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



// RewardItem 컴포넌트 분리
const RewardItem = React.memo(({ reward }: { reward: Reward }) => (
  <div className='flex items-center bg-white rounded-lg p-2 shadow-sm border border-yellow-200 w-full'>
    {reward.thumbnail ? (
      <div className='w-10 h-10 rounded overflow-hidden mr-2'>
        <Image
          src={getCdnImageUrl(reward.thumbnail)}
          alt={getLocalizedString(reward.title)}
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
  const { t } = useLanguageStore();
  const status = useMemo(() => {
    if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
    const now = new Date();
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    if (now < start) return VOTE_STATUS.UPCOMING;
    if (now > end) return VOTE_STATUS.COMPLETED;
    return VOTE_STATUS.ONGOING;
  }, [vote.startAt, vote.stopAt]);

  return (
    <Link href={`/vote/${vote.id}`}>
      <div className='bg-gradient-to-br from-white to-gray-50 rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 h-full flex flex-col'>
        <div className='absolute top-3 right-3 z-10 flex flex-wrap gap-1 justify-end max-w-[75%]'>
          <span
            className={`flex items-center px-3 py-1.5 rounded-full text-sm font-bold whitespace-nowrap ${
              STATUS_TAG_COLORS[status]
            }`}
          >
            {getStatusText(status, t)}
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

        <div className='p-4 sm:p-5 flex-1 flex flex-col'>
          <div className='flex flex-wrap gap-1 mb-3'>
            {vote.voteCategory && (
              <span
                className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ${
                  CATEGORY_COLORS[vote.voteCategory as keyof typeof CATEGORY_COLORS] ||
                  'bg-gray-100 text-gray-800 border border-gray-200'
                }`}
              >
                {t(`label_vote_${vote.voteCategory}`)}
              </span>
            )}
            {vote.voteSubCategory && (
              <span
                className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ${
                  SUB_CATEGORY_COLORS[vote.voteSubCategory as keyof typeof SUB_CATEGORY_COLORS] ||
                  'bg-gray-50 text-gray-600 border border-gray-100'
                }`}
              >
                {t(`compatibility_gender_${vote.voteSubCategory}`)}
              </span>
            )}
          </div>

          <h3 className='font-extrabold text-base sm:text-lg mb-4 text-gray-900 line-clamp-2 min-h-[2.5rem] p-2 relative group'>
            {getLocalizedString(vote.title)}
            <span className='absolute bottom-0 left-2 right-2 h-[2px] bg-primary/30 group-hover:bg-primary/50 transition-colors duration-300'></span>
          </h3>

          <div className='flex justify-center mb-4'>
            <CountdownTimer 
              startTime={vote.startAt} 
              endTime={vote.stopAt} 
              status={status === VOTE_STATUS.UPCOMING ? 'scheduled' : 'in_progress'} 
            />
          </div>

          <div className='flex-1'>
            <VoteItems vote={vote} />
          </div>

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
                <span className='text-sm sm:text-base'>
                  {t('text_vote_reward', {'count': vote.rewards.length.toString()})}
                </span>
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
              <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between text-sm gap-1 sm:gap-0'>
                <div className='flex items-center space-x-2 bg-primary/5 rounded-lg px-3 py-2'>
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-primary" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd" />
                  </svg>
                  <span className='text-primary font-medium'>
                    {format(new Date(vote.startAt), 'MM.dd HH:mm', { locale: ko })} ~{' '}
                    {format(new Date(vote.stopAt), 'MM.dd HH:mm', { locale: ko })}
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </Link>
  );
});

VoteCard.displayName = 'VoteCard';

const getStatusText = (status: VoteStatus, t: (key: string) => string): string => {
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

// StatusFilter 컴포넌트 분리
const StatusFilter = React.memo(({ 
  selectedStatus, 
  setSelectedStatus, 
  t 
}: { 
  selectedStatus: VoteStatus | 'all', 
  setSelectedStatus: (status: VoteStatus | 'all') => void,
  t: (key: string) => string 
}) => {
  const getButtonStyle = (status: VoteStatus | 'all') =>
    selectedStatus === status
      ? 'px-4 py-2 rounded-lg bg-blue-500 text-white font-bold mx-1 shadow'
      : 'px-4 py-2 rounded-lg bg-gray-200 text-gray-700 mx-1 hover:bg-blue-100';

  const getButtonText = (status: VoteStatus | 'all') => {
    switch (status) {
      case 'all':
        return t('label_tabbar_vote_all');
      case VOTE_STATUS.ONGOING:
        return t('label_tabbar_vote_active');
      case VOTE_STATUS.UPCOMING:
        return t('label_tabbar_vote_upcoming');
      case VOTE_STATUS.COMPLETED:
        return t('label_tabbar_vote_end');
      default:
        return '';
    }
  };

  return (
    <div className="flex space-x-2">
      <button
        onClick={() => setSelectedStatus('all')}
        className={getButtonStyle('all')}
        aria-label={t('label_tabbar_vote_all')}
        aria-pressed={selectedStatus === 'all'}
      >
        {getButtonText('all')}
      </button>
      <button
        onClick={() => setSelectedStatus(VOTE_STATUS.ONGOING)}
        className={getButtonStyle(VOTE_STATUS.ONGOING)}
        aria-label={t('label_tabbar_vote_active')}
        aria-pressed={selectedStatus === VOTE_STATUS.ONGOING}
      >
        {getButtonText(VOTE_STATUS.ONGOING)}
      </button>
      <button
        onClick={() => setSelectedStatus(VOTE_STATUS.UPCOMING)}
        className={getButtonStyle(VOTE_STATUS.UPCOMING)}
        aria-label={t('label_tabbar_vote_upcoming')}
        aria-pressed={selectedStatus === VOTE_STATUS.UPCOMING}
      >
        {getButtonText(VOTE_STATUS.UPCOMING)}
      </button>
      <button
        onClick={() => setSelectedStatus(VOTE_STATUS.COMPLETED)}
        className={getButtonStyle(VOTE_STATUS.COMPLETED)}
        aria-label={t('label_tabbar_vote_end')}
        aria-pressed={selectedStatus === VOTE_STATUS.COMPLETED}
      >
        {getButtonText(VOTE_STATUS.COMPLETED)}
      </button>
    </div>
  );
});

StatusFilter.displayName = 'StatusFilter';

// LoadingSkeleton 컴포넌트 분리
const LoadingSkeleton = React.memo(() => (
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
));

LoadingSkeleton.displayName = 'LoadingSkeleton';

// EmptyState 컴포넌트 분리
const EmptyState = React.memo(({ selectedStatus, t }: { selectedStatus: VoteStatus | 'all', t: (key: string) => string }) => {
  const getMessage = () => {
    if (selectedStatus === VOTE_STATUS.ONGOING) {
      return '진행 중인 투표가 없습니다.';
    } else if (selectedStatus === VOTE_STATUS.UPCOMING) {
      return '예정된 투표가 없습니다.';
    } else {
      return '종료된 투표가 없습니다.';
    }
  };

  return (
    <div className='bg-gray-100 p-6 rounded-lg text-center'>
      <p className='text-gray-500'>
        {getMessage()}
      </p>
    </div>
  );
});

EmptyState.displayName = 'EmptyState';

const VoteList: React.FC = () => {
  const [mounted, setMounted] = useState(false);
  const [votes, setVotes] = useState<Vote[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [selectedStatus, setSelectedStatus] = useState<VoteStatus | 'all'>('all');
  const [error, setError] = useState<string | null>(null);
  const { t } = useLanguageStore();
  const loadingRef = useRef<HTMLDivElement>(null);
  const PAGE_SIZE = 6;
  const isFetching = useRef(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const updateVoteData = useCallback(async (pageNum: number = 1, append: boolean = false) => {
    if (isFetching.current) return;
    
    try {
      isFetching.current = true;
      setLoading(true);
      setError(null);
      
      const votesData = await getVotes('votes');
      const start = (pageNum - 1) * PAGE_SIZE;
      const end = start + PAGE_SIZE;
      const paginatedData = votesData.slice(start, end);

      if (append) {
        setVotes(prev => [...prev, ...paginatedData]);
      } else {
        setVotes(paginatedData);
      }

      setHasMore(end < votesData.length);
    } catch (error) {
      console.error('투표 데이터를 가져오는 중 오류가 발생했습니다:', error);
      setError('데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
      isFetching.current = false;
    }
  }, []);

  // 초기 데이터 로드
  useEffect(() => {
    if (mounted) {
      updateVoteData(1, false);
    }
  }, [mounted, updateVoteData]);

  // 상태 변경 시 데이터 리셋
  useEffect(() => {
    if (mounted) {
      setPage(1);
      updateVoteData(1, false);
    }
  }, [selectedStatus, updateVoteData, mounted]);

  // 스크롤 감지 및 추가 데이터 로드
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const first = entries[0];
        if (first.isIntersecting && hasMore && !loading && !isFetching.current) {
          const nextPage = page + 1;
          setPage(nextPage);
          updateVoteData(nextPage, true);
        }
      },
      { threshold: 0.1 }
    );

    const currentLoadingRef = loadingRef.current;
    if (currentLoadingRef) {
      observer.observe(currentLoadingRef);
    }

    return () => {
      if (currentLoadingRef) {
        observer.unobserve(currentLoadingRef);
      }
    };
  }, [hasMore, loading, page, updateVoteData]);

  const filteredVotes = useMemo(() => {
    if (selectedStatus === 'all') {
      return votes.sort((a, b) => {
        const now = new Date();
        const aStart = a.startAt ? new Date(a.startAt) : null;
        const aEnd = a.stopAt ? new Date(a.stopAt) : null;
        const bStart = b.startAt ? new Date(b.startAt) : null;
        const bEnd = b.stopAt ? new Date(b.stopAt) : null;

        // 진행중인 투표 우선
        const aIsOngoing = aStart && aEnd && now >= aStart && now <= aEnd;
        const bIsOngoing = bStart && bEnd && now >= bStart && now <= bEnd;
        if (aIsOngoing && !bIsOngoing) return -1;
        if (!aIsOngoing && bIsOngoing) return 1;

        // 예정된 투표 다음
        const aIsUpcoming = aStart && now < aStart;
        const bIsUpcoming = bStart && now < bStart;
        if (aIsUpcoming && !bIsUpcoming) return -1;
        if (!aIsUpcoming && bIsUpcoming) return 1;

        // 종료된 투표 마지막
        return 0;
      });
    }
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

  if (error) {
    return (
      <div className="text-red-500 p-4 rounded-lg bg-red-50 flex flex-col items-center">
        <p>{error}</p>
        <button
          className="mt-2 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          onClick={() => updateVoteData(page, false)}
        >
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <section className="w-full">
      <div className='flex justify-center items-center mb-6'>
        <StatusFilter 
          selectedStatus={selectedStatus} 
          setSelectedStatus={setSelectedStatus}
          t={t}
        />
      </div>

      {loading && votes.length === 0 ? (
        <LoadingSkeleton />
      ) : votes.length === 0 ? (
        <div className='bg-gray-100 p-6 rounded-lg text-center'>
          <p className='text-gray-500'>투표가 없습니다.</p>
        </div>
      ) : filteredVotes.length === 0 ? (
        <EmptyState selectedStatus={selectedStatus} t={t} />
      ) : (
        <>
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            {filteredVotes.map((vote) => (
              <VoteCard key={vote.id} vote={vote} />
            ))}
          </div>
          {hasMore && (
            <div
              ref={loadingRef}
              className="w-full flex justify-center items-center py-4"
            >
              {loading ? (
                <div className="animate-pulse flex space-x-2">
                  <div className="w-2 h-2 bg-gray-400 rounded-full"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full"></div>
                </div>
              ) : (
                <div className="h-4"></div>
              )}
            </div>
          )}
        </>
      )}
    </section>
  );
};

export default React.memo(VoteList);
