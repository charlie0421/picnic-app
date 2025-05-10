'use client';

import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Reward, Vote, VoteItem } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { useLanguageStore } from '@/stores/languageStore';
import UpcomingVoteItems from './vote/UpcomingVoteItems';
import OngoingVoteItems from './vote/OngoingVoteItems';
import CompletedVoteItems from './vote/CompletedVoteItems';
import CountdownTimer from '@/components/features/CountdownTimer';
import { useRouter, useSearchParams } from 'next/navigation';
import { getLocalizedString } from '@/utils/api/strings';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import RewardItem from '@/components/common/RewardItem';

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];

const VOTE_AREAS = {
  KPOP: 'kpop',
  MUSICAL: 'musical',
} as const;

type VoteArea = (typeof VOTE_AREAS)[keyof typeof VOTE_AREAS];

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

// VoteItems 컴포넌트 분리
const VoteItems = React.memo(
  ({
    vote,
  }: {
    vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
  }) => {
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
    const now = new Date();
    const prevStatus =
      !prevProps.vote.startAt || !prevProps.vote.stopAt
        ? VOTE_STATUS.UPCOMING
        : now < new Date(prevProps.vote.startAt)
        ? VOTE_STATUS.UPCOMING
        : now > new Date(prevProps.vote.stopAt)
        ? VOTE_STATUS.COMPLETED
        : VOTE_STATUS.ONGOING;

    const nextStatus =
      !nextProps.vote.startAt || !nextProps.vote.stopAt
        ? VOTE_STATUS.UPCOMING
        : now < new Date(nextProps.vote.startAt)
        ? VOTE_STATUS.UPCOMING
        : now > new Date(nextProps.vote.stopAt)
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

            {vote.reward && vote.reward.length > 0 && (
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
                      count: vote.reward.length.toString(),
                    })}
                  </span>
                </div>
                <div className='flex flex-wrap gap-2'>
                  {vote.reward.slice(0, 2).map((reward) => (
                    <RewardItem key={reward.id} reward={reward} />
                  ))}
                  {vote.reward.length > 2 && (
                    <div className='w-full text-center'>
                      <span className='text-xs text-gray-500'>
                        +{vote.reward.length - 2}개 더보기
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

// StatusFilter 컴포넌트 수정
const StatusFilter = React.memo(
  ({
    selectedStatus,
    setSelectedStatus,
    t,
  }: {
    selectedStatus: VoteStatus;
    setSelectedStatus: (status: VoteStatus) => void;
    t: (key: string) => string;
  }) => {
    const { translations } = useLanguageStore();

    const getButtonText = useCallback(
      (status: VoteStatus) => {
        switch (status) {
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

// AreaFilter 컴포넌트 수정
const AreaFilter = React.memo(
  ({
    selectedArea,
    setSelectedArea,
    t,
  }: {
    selectedArea: VoteArea;
    setSelectedArea: (area: VoteArea) => void;
    t: (key: string) => string;
  }) => {
    return (
      <div className='flex flex-wrap justify-center gap-1.5 sm:gap-2'>
        <button
          onClick={() => setSelectedArea(VOTE_AREAS.KPOP)}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedArea === VOTE_AREAS.KPOP
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
        >
          K-POP
        </button>
        <button
          onClick={() => setSelectedArea(VOTE_AREAS.MUSICAL)}
          className={`px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg text-xs sm:text-sm font-medium ${
            selectedArea === VOTE_AREAS.MUSICAL
              ? 'bg-primary text-white shadow-sm'
              : 'bg-gray-100 text-gray-600 hover:bg-primary/10 hover:text-primary'
          }`}
        >
          K-MUSICAL
        </button>
      </div>
    );
  },
);

AreaFilter.displayName = 'AreaFilter';

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
    selectedStatus: VoteStatus;
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
  const { supabase } = useSupabase();
  const { t, currentLanguage } = useLanguageStore();
  const router = useRouter();
  const searchParams = useSearchParams();
  const PAGE_SIZE = 8;
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<VoteStatus>(
    (searchParams.get('status') as VoteStatus) || VOTE_STATUS.ONGOING
  );
  const [selectedArea, setSelectedArea] = useState<VoteArea>(
    (searchParams.get('area') as VoteArea) || VOTE_AREAS.KPOP
  );
  const [votes, setVotes] = useState<Vote[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const prevVotesRef = useRef<Vote[]>([]);

  // URL 파라미터 업데이트 함수
  const updateUrlParams = useCallback((status: VoteStatus, area: VoteArea) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('status', status);
    params.set('area', area);
    router.push(`?${params.toString()}`, { scroll: false });
  }, [router, searchParams]);

  const fetchVotes = useCallback(
    async (isRefresh = false) => {
      if (isTransitioning && !isRefresh) return;

      try {
        if (isRefresh) {
          setIsRefreshing(true);
        } else {
          setIsLoading(true);
        }

        const now = new Date().toISOString();
        let query = supabase
          .from('vote')
          .select(
            `
          *,
          vote_item!vote_id (
            id,
            vote_id,
            artist_id,
            group_id,
            vote_total,
            created_at,
            updated_at,
            deleted_at,
            artist (
              id,
              name,
              image,
              artist_group (
                id,
                name
              )
            )
          ),
          vote_reward (
            reward_id,
            reward:reward_id (*)
          )
        `,
          )
          .is('deleted_at', null);

        // 상태별 필터링
        switch (selectedStatus) {
          case VOTE_STATUS.UPCOMING:
            query = query.gt('start_at', now);
            break;
          case VOTE_STATUS.ONGOING:
            query = query.lte('start_at', now).gte('stop_at', now);
            break;
          case VOTE_STATUS.COMPLETED:
            query = query.lt('stop_at', now);
            break;
        }

        // 영역별 필터링
        query = query.eq('area', selectedArea);

        // 정렬
        query = query.order('start_at', { ascending: false });

        const { data: voteData, error: voteError } = await query;

        if (voteError) {
          console.error('Vote fetch error:', voteError);
          throw voteError;
        }

        if (!voteData || voteData.length === 0) {
          console.log('No votes found');
          setVotes([]);
          setHasMore(false);
          return;
        }

        const formattedVotes = voteData.map((vote: any) => ({
          ...vote,
          deletedAt: vote.deleted_at,
          startAt: vote.start_at,
          stopAt: vote.stop_at,
          createdAt: vote.created_at,
          updatedAt: vote.updated_at,
          mainImage: vote.main_image,
          resultImage: vote.result_image,
          waitImage: vote.wait_image,
          voteCategory: vote.vote_category,
          voteContent: vote.vote_content,
          voteSubCategory: vote.vote_sub_category,
          visibleAt: vote.visible_at,
          area: vote.area,
          voteItems: vote.vote_item
            ? vote.vote_item.map((item: any) => ({
                ...item,
                deletedAt: item.deleted_at,
                createdAt: item.created_at,
                updatedAt: item.updated_at,
                voteId: item.vote_id,
                artistId: item.artist_id,
                groupId: item.group_id,
                voteTotal: item.vote_total || 0,
                artist: item.artist
                  ? {
                      ...item.artist,
                      image: item.artist.image,
                    }
                  : null,
              }))
            : [],
          reward: vote.vote_reward
            ? vote.vote_reward.map((vr: any) => vr.reward).filter(Boolean)
            : [],
          title: vote.title || '제목 없음',
        }));

        // 이전 데이터를 유지하면서 새 데이터로 업데이트
        prevVotesRef.current = votes;
        setVotes(formattedVotes);
        setHasMore(formattedVotes.length >= PAGE_SIZE);
        setError(null);
      } catch (err) {
        console.error('투표 데이터 로드 오류:', err);
        setError(err as Error);
        setVotes([]);
        setHasMore(false);
      } finally {
        if (isRefresh) {
          setIsRefreshing(false);
        } else {
          setIsLoading(false);
        }
        setIsTransitioning(false);
      }
    },
    [supabase, selectedStatus, selectedArea, PAGE_SIZE, votes, isTransitioning],
  );

  // 상태 변경 핸들러
  const handleStatusChange = useCallback(async (status: VoteStatus) => {
    if (status === selectedStatus || isTransitioning) return;
    
    try {
      setIsTransitioning(true);
      setSelectedStatus(status);
      updateUrlParams(status, selectedArea);
      setPage(1);
      await fetchVotes(false);
    } catch (error) {
      console.error('상태 변경 중 오류 발생:', error);
    }
  }, [updateUrlParams, selectedArea, fetchVotes, selectedStatus, isTransitioning]);

  // 영역 변경 핸들러
  const handleAreaChange = useCallback(async (area: VoteArea) => {
    if (area === selectedArea || isTransitioning) return;
    
    try {
      setIsTransitioning(true);
      setSelectedArea(area);
      updateUrlParams(selectedStatus, area);
      setPage(1);
      await fetchVotes(false);
    } catch (error) {
      console.error('영역 변경 중 오류 발생:', error);
    }
  }, [updateUrlParams, selectedStatus, fetchVotes, selectedArea, isTransitioning]);

  // URL 파라미터 변경 감지
  useEffect(() => {
    const status = searchParams.get('status') as VoteStatus || VOTE_STATUS.ONGOING;
    const area = searchParams.get('area') as VoteArea || VOTE_AREAS.KPOP;
    
    if ((status !== selectedStatus || area !== selectedArea) && !isTransitioning) {
      const updateFilters = async () => {
        try {
          setIsTransitioning(true);
          setSelectedStatus(status);
          setSelectedArea(area);
          setPage(1);
          await fetchVotes(false);
        } catch (error) {
          console.error('URL 파라미터 변경 중 오류 발생:', error);
        }
      };
      
      updateFilters();
    }
  }, [searchParams, fetchVotes, selectedStatus, selectedArea, isTransitioning]);

  // 언어 변경 시 쿼리 재실행
  useEffect(() => {
    if (currentLanguage && !isTransitioning) {
      fetchVotes(false);
    }
  }, [currentLanguage, fetchVotes, isTransitioning]);

  // 전역 타이머 구독
  useEffect(() => {
    let isMounted = true;
    const timer = setInterval(() => {
      if (isMounted && !isTransitioning) {
        fetchVotes(true);
      }
    }, 1000);

    return () => {
      isMounted = false;
      clearInterval(timer);
    };
  }, [fetchVotes, isTransitioning]);

  // 표시할 투표 목록 계산
  const paginatedVotes = useMemo(() => {
    if (!votes) return [];

    const start = 0;
    const end = page * PAGE_SIZE;
    const paginatedData = votes.slice(start, end);
    setHasMore(end < votes.length);
    return paginatedData;
  }, [votes, page, PAGE_SIZE]);

  // 필터링된 투표 목록
  const filteredVotes = useMemo(() => {
    if (!paginatedVotes || paginatedVotes.length === 0) return [];
    return paginatedVotes;
  }, [paginatedVotes]);

  return (
    <section className='w-full'>
      <div className='flex justify-between items-center mb-6 px-4'>
        <div className='flex-1'>
          <AreaFilter
            selectedArea={selectedArea}
            setSelectedArea={handleAreaChange}
            t={t}
          />
        </div>
        <div className='flex-1 flex justify-end'>
          <StatusFilter
            selectedStatus={selectedStatus}
            setSelectedStatus={handleStatusChange}
            t={t}
          />
        </div>
      </div>

      <div className={`transition-all duration-300 ${isTransitioning ? 'opacity-50' : 'opacity-100'}`}>
        {isLoading && votes.length === 0 ? (
          <LoadingSkeleton />
        ) : votes.length === 0 ? (
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
              <div className='flex justify-center mt-8'>
                <button
                  onClick={() => setPage((prev) => prev + 1)}
                  className='px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors duration-200 flex items-center gap-2'
                  disabled={isLoading || isTransitioning}
                >
                  {isLoading ? (
                    <>
                      <div className='w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin'></div>
                      <span>Loading...</span>
                    </>
                  ) : (
                    <>
                      <span>{t('label_list_more')}</span>
                      <svg
                        xmlns='http://www.w3.org/2000/svg'
                        className='h-4 w-4'
                        viewBox='0 0 20 20'
                        fill='currentColor'
                      >
                        <path
                          fillRule='evenodd'
                          d='M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z'
                          clipRule='evenodd'
                        />
                      </svg>
                    </>
                  )}
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </section>
  );
};

export default React.memo(VoteList);
