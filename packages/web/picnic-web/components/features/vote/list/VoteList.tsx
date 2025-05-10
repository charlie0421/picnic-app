'use client';

import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { useRouter, useSearchParams } from 'next/navigation';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import VoteCard from '@/components/features/vote/list/VoteCard';
import VoteStatusFilter from '@/components/features/vote/list/VoteStatusFilter';
import VoteAreaFilter from '@/components/features/vote/list/VoteAreaFilter';
import VoteEmptyState from '@/components/features/vote/list/VoteEmptyState';
import VoteLoadingSkeleton from './VoteLoadingSkeleton';
import { Vote } from '@/types/interfaces';
import VoteInfiniteLoading from './VoteInfiniteLoading';

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
      <div className='flex justify-between items-center mb-4'>
        <div className='flex-1 flex justify-start'>
          <VoteAreaFilter
            selectedArea={selectedArea}
            onAreaChange={handleAreaChange}
          />
        </div>
        <div className='flex-1 flex justify-end'>
          <VoteStatusFilter
            selectedStatus={selectedStatus}
            onStatusChange={handleStatusChange}
          />
        </div>
      </div>

      <div className={`transition-all duration-300 ${isTransitioning ? 'opacity-50' : 'opacity-100'}`}>
        {isLoading && votes.length === 0 ? (
          <VoteLoadingSkeleton />
        ) : votes.length === 0 ? (
          <div className='bg-gray-100 p-6 rounded-lg text-center'>
            <p className='text-gray-500'>투표가 없습니다.</p>
          </div>
        ) : filteredVotes.length === 0 ? (
          <VoteEmptyState selectedStatus={selectedStatus} />
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
                      <VoteInfiniteLoading />
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
