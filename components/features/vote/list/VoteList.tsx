'use client';

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useLanguageStore } from '@/stores/languageStore';
import { useRouter, useSearchParams } from 'next/navigation';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { Vote } from '@/types/interfaces';
import { useVoteFilterStore, VOTE_STATUS, VOTE_AREAS } from '@/stores/voteFilterStore';
import VoteFilterSection from './VoteFilterSection';
import VoteListSection from './VoteListSection';
import VotePagination from './VotePagination';

const VoteList: React.FC = () => {
  const { supabase } = useSupabase();
  const { currentLanguage } = useLanguageStore();
  const router = useRouter();
  const searchParams = useSearchParams();
  const PAGE_SIZE = 8;
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const { selectedStatus, selectedArea } = useVoteFilterStore();
  const [votes, setVotes] = useState<Vote[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [isTransitioning, setIsTransitioning] = useState(false);

  const fetchVotes = useCallback(
    async (isRefresh = false) => {
      if (isTransitioning && !isRefresh) return;

      try {
        setIsLoading(true);

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

        setVotes(formattedVotes);
        setHasMore(formattedVotes.length >= PAGE_SIZE);
        setError(null);
      } catch (err) {
        console.error('투표 데이터 로드 오류:', err);
        setError(err as Error);
        setVotes([]);
        setHasMore(false);
      } finally {
        setIsLoading(false);
        setIsTransitioning(false);
      }
    },
    [supabase, selectedStatus, selectedArea, PAGE_SIZE, isTransitioning],
  );

  // URL 파라미터와 필터 상태 변경 감지
  useEffect(() => {
    const status = searchParams.get('status') as typeof selectedStatus || VOTE_STATUS.ONGOING;
    const area = searchParams.get('area') as typeof selectedArea || VOTE_AREAS.KPOP;
    
    if (!isLoading && !isTransitioning) {
      const updateData = async () => {
        try {
          setIsTransitioning(true);
          setPage(1);
          await fetchVotes(false);
        } catch (error) {
          console.error('데이터 업데이트 중 오류 발생:', error);
        } finally {
          setIsTransitioning(false);
        }
      };
      
      updateData();
    }
  }, [searchParams, selectedStatus, selectedArea]);

  // 언어 변경 시 쿼리 재실행
  useEffect(() => {
    if (currentLanguage && !isTransitioning) {
      fetchVotes(false);
    }
  }, [currentLanguage, fetchVotes, isTransitioning]);

  // 표시할 투표 목록 계산
  const paginatedVotes = useMemo(() => {
    if (!votes) return [];

    const start = 0;
    const end = page * PAGE_SIZE;
    const paginatedData = votes.slice(start, end);
    setHasMore(end < votes.length);
    return paginatedData;
  }, [votes, page, PAGE_SIZE]);

  const handleVoteClick = useCallback((voteId: string) => {
    router.push(`/vote/${voteId}`);
  }, [router]);

  const handleLoadMore = useCallback(() => {
    setPage((prev) => prev + 1);
  }, []);

  return (
    <section className='w-full'>
      {/* 기존 리스트 UI */}
      <VoteFilterSection />
      <VoteListSection
        votes={paginatedVotes}
        isLoading={isLoading}
        isTransitioning={isTransitioning}
        onVoteClick={handleVoteClick}
      />
      <VotePagination
        hasMore={hasMore}
        isLoading={isLoading}
        isTransitioning={isTransitioning}
        onLoadMore={handleLoadMore}
      />
    </section>
  );
};

export default React.memo(VoteList);
