'use client';

import React, {
  useEffect,
  useState,
  useMemo,
  useCallback,
  useRef,
} from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { format, differenceInDays, differenceInSeconds } from 'date-fns';
import { ko } from 'date-fns/locale';
import { getVotes } from '@/utils/api/queries';
import { useLanguageStore } from '@/stores/languageStore';
import UpcomingVoteItems from './vote/UpcomingVoteItems';
import OngoingVoteItems from './vote/OngoingVoteItems';
import CompletedVoteItems from './vote/CompletedVoteItems';
import CountdownTimer from '@/components/features/CountdownTimer';
import { useRouter } from 'next/navigation';
import { Database } from '@/types/supabase';
import { Json } from '@/types/supabase';
import { getLocalizedString } from '@/utils/api/strings';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { useSafeData } from '@/utils/api/hydration-safe-data';

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
    <div className='flex-1 min-w-0'>
      <div className='text-sm font-medium text-gray-900 truncate'>
        {getLocalizedString(reward.title) || '리워드 정보'}
      </div>
    </div>
  </div>
));

RewardItem.displayName = 'RewardItem';

// VoteItems 컴포넌트 분리
const VoteItems = React.memo(
  ({
    vote,
  }: {
    vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
  }) => {
    const status = useMemo(() => {
      if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
      const now = new Date();
      const start = new Date(vote.startAt);
      const end = new Date(vote.stopAt);
      if (now < start) return VOTE_STATUS.UPCOMING;
      if (now > end) return VOTE_STATUS.COMPLETED;
      return VOTE_STATUS.ONGOING;
    }, [vote.startAt, vote.stopAt]);

    // 투표 업데이트 핸들러
    const handleVoteChange = useCallback(
      (voteId: string | number, itemId: string | number, newTotal: number) => {
        console.log(
          `VoteItems: 투표 변경 감지 - ${voteId}:${itemId} = ${newTotal}`,
        );
        // 여기서 추가 로직 구현 가능
      },
      [],
    );

    switch (status) {
      case VOTE_STATUS.UPCOMING:
        return <UpcomingVoteItems voteItems={vote.voteItems} />;
      case VOTE_STATUS.ONGOING:
        return <OngoingVoteItems vote={vote} onVoteChange={handleVoteChange} />;
      case VOTE_STATUS.COMPLETED:
        return <CompletedVoteItems vote={vote} />;
      default:
        return null;
    }
  },
  (prevProps, nextProps) => {
    // 투표 상태가 변경될 때만 리렌더링
    const prevStatus =
      !prevProps.vote.startAt || !prevProps.vote.stopAt
        ? VOTE_STATUS.UPCOMING
        : new Date() < new Date(prevProps.vote.startAt)
        ? VOTE_STATUS.UPCOMING
        : new Date() > new Date(prevProps.vote.stopAt)
        ? VOTE_STATUS.COMPLETED
        : VOTE_STATUS.ONGOING;

    const nextStatus =
      !nextProps.vote.startAt || !nextProps.vote.stopAt
        ? VOTE_STATUS.UPCOMING
        : new Date() < new Date(nextProps.vote.startAt)
        ? VOTE_STATUS.UPCOMING
        : new Date() > new Date(nextProps.vote.stopAt)
        ? VOTE_STATUS.COMPLETED
        : VOTE_STATUS.ONGOING;

    return prevStatus === nextStatus;
  },
);

VoteItems.displayName = 'VoteItems';

// VoteCard 컴포넌트 분리
const VoteCard = React.memo(
  ({ vote, onClick }: { vote: Vote; onClick?: () => void }) => {
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
          <div className='absolute top-2 right-2 z-10 flex flex-wrap gap-1 justify-end max-w-[75%]'>
            <span
              className={`flex items-center px-2 py-0.5 rounded-full text-xs font-medium shadow-sm whitespace-nowrap ${STATUS_TAG_COLORS[status]}`}
            >
              {getStatusText(status, t)}
            </span>
          </div>

          <div className='relative'>
            {vote.mainImage && (
              <div className='h-48 sm:h-56 md:h-64 bg-gray-200 relative'>
                <Image
                  src={getCdnImageUrl(vote.mainImage)}
                  alt={vote.title}
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

            {vote.rewards && vote.rewards.length > 0 && (
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
                      count: vote.rewards.length.toString(),
                    })}
                  </span>
                </div>
                <div className='flex flex-wrap gap-2'>
                  {vote.rewards.slice(0, 2).map((reward) => (
                    <RewardItem key={reward.id} reward={reward} />
                  ))}
                  {vote.rewards.length > 2 && (
                    <div className='w-full text-center'>
                      <span className='text-xs text-gray-500'>
                        +{vote.rewards.length - 2}개 더보기
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

// StatusFilter 컴포넌트 분리
const StatusFilter = React.memo(
  ({
    selectedStatus,
    setSelectedStatus,
    t,
  }: {
    selectedStatus: VoteStatus | 'all';
    setSelectedStatus: (status: VoteStatus | 'all') => void;
    t: (key: string) => string;
  }) => {
    const { translations } = useLanguageStore();

    const getButtonText = useCallback(
      (status: VoteStatus | 'all') => {
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
      },
      [t],
    );

    return (
      <div className='flex flex-wrap justify-center gap-1.5 sm:gap-2'>
        <button
          onClick={() => setSelectedStatus('all')}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedStatus === 'all'
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
          aria-label={t('label_tabbar_vote_all')}
          aria-pressed={selectedStatus === 'all'}
        >
          {getButtonText('all')}
        </button>
        <button
          onClick={() => setSelectedStatus(VOTE_STATUS.ONGOING)}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedStatus === VOTE_STATUS.ONGOING
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
          aria-label={t('label_tabbar_vote_active')}
          aria-pressed={selectedStatus === VOTE_STATUS.ONGOING}
        >
          {getButtonText(VOTE_STATUS.ONGOING)}
        </button>
        <button
          onClick={() => setSelectedStatus(VOTE_STATUS.UPCOMING)}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedStatus === VOTE_STATUS.UPCOMING
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
          aria-label={t('label_tabbar_vote_upcoming')}
          aria-pressed={selectedStatus === VOTE_STATUS.UPCOMING}
        >
          {getButtonText(VOTE_STATUS.UPCOMING)}
        </button>
        <button
          onClick={() => setSelectedStatus(VOTE_STATUS.COMPLETED)}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedStatus === VOTE_STATUS.COMPLETED
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
          aria-label={t('label_tabbar_vote_end')}
          aria-pressed={selectedStatus === VOTE_STATUS.COMPLETED}
        >
          {getButtonText(VOTE_STATUS.COMPLETED)}
        </button>
      </div>
    );
  },
);

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

// 무한 로딩을 위한 로딩 인디케이터 컴포넌트 추가
const InfiniteLoadingIndicator = React.memo(() => (
  <div className='w-full flex flex-col items-center justify-center py-4'>
    <div className='relative w-8 h-8'>
      <div className='absolute top-0 left-0 w-full h-full border-2 border-primary/20 rounded-full'></div>
      <div className='absolute top-0 left-0 w-full h-full border-2 border-primary border-t-transparent rounded-full animate-spin'></div>
    </div>
  </div>
));

InfiniteLoadingIndicator.displayName = 'InfiniteLoadingIndicator';

// EmptyState 컴포넌트 분리
const EmptyState = React.memo(
  ({
    selectedStatus,
    t,
  }: {
    selectedStatus: VoteStatus | 'all';
    t: (key: string) => string;
  }) => {
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
        <p className='text-gray-500'>{getMessage()}</p>
      </div>
    );
  },
);

EmptyState.displayName = 'EmptyState';

const VoteList: React.FC = () => {
  const { supabase, isReady } = useSupabase();
  const { t } = useLanguageStore();
  const router = useRouter();
  const PAGE_SIZE = 6;

  // 데이터 로드 및 로딩 상태 관리
  const {
    data: allVotes,
    isLoading,
    error,
    mounted,
  } = useSafeData(
    async () => {
      try {
        // Supabase가 준비된 후에만 데이터를 요청
        if (!isReady) return [];
        const votesData = await getVotes('votes');
        return votesData;
      } catch (err) {
        console.error('투표 데이터 로드 오류:', err);
        throw err;
      }
    },
    [],
    [isReady], // Supabase가 준비되면 재실행
  );

  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<VoteStatus | 'all'>(
    'all',
  );
  const loadingRef = useRef<HTMLDivElement>(null);

  // 표시할 투표 목록 계산
  const votes = useMemo(() => {
    if (!allVotes) return [];
    const start = 0;
    const end = page * PAGE_SIZE;
    const paginatedData = allVotes.slice(start, end);
    setHasMore(end < allVotes.length);
    return paginatedData;
  }, [allVotes, page, PAGE_SIZE]);

  // 필터링된 투표 목록
  const filteredVotes = useMemo(() => {
    if (!votes || votes.length === 0) return [];

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
      if (!vote.startAt || !vote.stopAt)
        return selectedStatus === VOTE_STATUS.UPCOMING;
      const now = new Date();
      const start = new Date(vote.startAt);
      const end = new Date(vote.stopAt);
      if (selectedStatus === VOTE_STATUS.UPCOMING) return now < start;
      if (selectedStatus === VOTE_STATUS.ONGOING)
        return now >= start && now <= end;
      return now > end;
    });
  }, [votes, selectedStatus]);

  // 스크롤 감지 및 추가 데이터 로드
  useEffect(() => {
    if (!mounted) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const first = entries[0];
        if (first.isIntersecting && hasMore && !isLoading) {
          setPage((prev) => prev + 1);
        }
      },
      { threshold: 0.1 },
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
  }, [hasMore, isLoading, mounted]);

  // 상태가 변경되면 페이지 리셋
  useEffect(() => {
    if (mounted) {
      setPage(1);
    }
  }, [selectedStatus, mounted]);

  // 컴포넌트가 마운트되기 전에는 렌더링하지 않음
  if (!mounted) return null;

  // 오류 발생 시
  if (error) {
    return (
      <div className='text-red-500 p-4 rounded-lg bg-red-50 flex flex-col items-center'>
        <p>데이터를 불러오는 중 오류가 발생했습니다.</p>
        <button
          className='mt-2 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600'
          onClick={() => window.location.reload()}
        >
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <section className='w-full'>
      <div className='flex justify-center items-center mb-6'>
        <StatusFilter
          selectedStatus={selectedStatus}
          setSelectedStatus={setSelectedStatus}
          t={t}
        />
      </div>

      {isLoading && votes.length === 0 ? (
        <LoadingSkeleton />
      ) : allVotes?.length === 0 ? (
        <div className='bg-gray-100 p-6 rounded-lg text-center'>
          <p className='text-gray-500'>투표가 없습니다.</p>
        </div>
      ) : filteredVotes.length === 0 ? (
        <EmptyState selectedStatus={selectedStatus} t={t} />
      ) : (
        <>
          <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6 md:gap-8'>
            {filteredVotes.map((vote) => (
              <VoteCard
                key={vote.id}
                vote={vote}
                onClick={() => router.push(`/vote/${vote.id}`)}
              />
            ))}
          </div>
          {hasMore && (
            <div ref={loadingRef} className='w-full'>
              {isLoading ? (
                <InfiniteLoadingIndicator />
              ) : (
                <div className='h-4'></div>
              )}
            </div>
          )}
        </>
      )}
    </section>
  );
};

export default React.memo(VoteList);
