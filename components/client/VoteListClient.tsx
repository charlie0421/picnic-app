'use client';

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useLanguageStore } from '@/stores/languageStore';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { useVoteFilterStore, VOTE_STATUS, VOTE_AREAS } from '@/stores/voteFilterStore';
import { Vote } from '@/types/interfaces';
import { LoadingSpinner } from './index';

// VoteListClient 컴포넌트는 VoteList 컴포넌트의 클라이언트 부분입니다.
// 원래 components/features/vote/list/VoteList.tsx의 내용을 여기로 이동했습니다.

interface VoteListClientProps {
  initialVotes: Vote[];
  initialStatus: string;
  initialArea: string;
  error?: string;
}

const VoteListClient: React.FC<VoteListClientProps> = ({ 
  initialVotes,
  initialStatus,
  initialArea,
  error: initialError
}) => {
  const { supabase } = useSupabase();
  const { currentLanguage } = useLanguageStore();
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSelectedStatus, setSelectedArea, selectedStatus, selectedArea } = useVoteFilterStore();
  
  const PAGE_SIZE = 8;
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [votes, setVotes] = useState<Vote[]>(initialVotes);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(initialError || null);
  const [isTransitioning, setIsTransitioning] = useState(false);

  // 상태 초기화
  useEffect(() => {
    setSelectedStatus(initialStatus as any);
    setSelectedArea(initialArea as any);
  }, [initialStatus, initialArea, setSelectedStatus, setSelectedArea]);

  // 클라이언트에서 추가 데이터 페칭 (필터 변경 시)
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
        setError((err as Error).message);
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
    
    if (status !== selectedStatus || area !== selectedArea) {
      setSelectedStatus(status);
      setSelectedArea(area);
    }

    // 초기 로드가 아닐 때만 클라이언트 측에서 추가 페치
    if (!initialVotes.length || status !== initialStatus || area !== initialArea) {
      const updateData = async () => {
        try {
          setIsTransitioning(true);
          setPage(1);
          await fetchVotes(true);
        } catch (error) {
          console.error('데이터 업데이트 중 오류 발생:', error);
        } finally {
          setIsTransitioning(false);
        }
      };
      
      updateData();
    }
  }, [searchParams, selectedStatus, selectedArea, initialVotes.length, initialStatus, initialArea, fetchVotes, setSelectedStatus, setSelectedArea]);

  // 언어 변경 시 쿼리 재실행
  useEffect(() => {
    if (currentLanguage && !isTransitioning && votes.length > 0) {
      fetchVotes(false);
    }
  }, [currentLanguage, fetchVotes, isTransitioning, votes.length]);

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

  // 데이터가 없을 때 표시할 내용
  if (votes.length === 0 && !isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[300px] text-center">
        <p className="text-gray-500">투표가 없습니다.</p>
      </div>
    );
  }

  // 로딩 중일 때 표시할 내용
  if (isLoading) {
    return <LoadingSpinner />;
  }

  // 오류가 있을 때 표시할 내용
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[300px] text-center">
        <p className="text-red-500">오류가 발생했습니다: {error}</p>
        <button 
          className="mt-4 px-4 py-2 bg-primary text-white rounded"
          onClick={() => fetchVotes(true)}
        >
          다시 시도
        </button>
      </div>
    );
  }

  return (
    <section className='w-full'>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {paginatedVotes.map((vote) => (
          <div 
            key={vote.id}
            className="bg-white rounded-lg shadow-md overflow-hidden cursor-pointer hover:shadow-lg transition-shadow"
            onClick={() => handleVoteClick(vote.id)}
          >
            <div className="relative aspect-video">
              <img 
                src={vote.mainImage || '/images/default-vote.jpg'} 
                alt={vote.title}
                className="w-full h-full object-cover"
              />
            </div>
            <div className="p-4">
              <h3 className="text-lg font-bold truncate">{vote.title}</h3>
              <p className="text-sm text-gray-500 mt-1">
                {new Date(vote.startAt).toLocaleDateString()} ~ {new Date(vote.stopAt).toLocaleDateString()}
              </p>
            </div>
          </div>
        ))}
      </div>

      {hasMore && (
        <div className="flex justify-center mt-8">
          <button 
            className="px-6 py-2 bg-primary text-white rounded-full hover:bg-primary/80 transition-colors"
            onClick={handleLoadMore}
          >
            더 보기
          </button>
        </div>
      )}
    </section>
  );
};

export default VoteListClient; 