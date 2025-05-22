import React, { Suspense } from 'react';
import { VoteListClient } from '@/components/client';
import { VOTE_STATUS, VOTE_AREAS } from '@/stores/voteFilterStore';
import { getList, TABLES, executeCustomQuery } from '@/lib/data-fetching/supabase-service';
import { LoadingState } from '@/components/server';
import { createServerSupabaseClient } from '@/lib/supabase/server';

interface VoteListProps {
  initialStatus?: string;
  initialArea?: string;
}

/**
 * 투표 목록 데이터를 가져오는 서버 컴포넌트
 */
async function VoteDataFetcher({ 
  initialStatus = VOTE_STATUS.ONGOING,
  initialArea = VOTE_AREAS.KPOP 
}: VoteListProps) {
  const now = new Date().toISOString();
  
  // 커스텀 쿼리 실행 (복잡한 조인을 위해 executeCustomQuery 사용)
  const voteData = await executeCustomQuery(async (supabase) => {
    let query = supabase
      .from('vote')
      .select(`
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
      `)
      .is('deleted_at', null);

    // 상태별 필터링
    switch (initialStatus) {
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
    if (initialArea) {
      query = query.eq('area', initialArea);
    }

    // 정렬
    query = query.order('start_at', { ascending: false });
    
    return query;
  });

  if (!voteData || voteData.length === 0) {
    return <VoteListClient 
      initialVotes={[]} 
      initialStatus={initialStatus || VOTE_STATUS.ONGOING} 
      initialArea={initialArea || VOTE_AREAS.KPOP} 
    />;
  }

  // 서버에서 데이터 포맷팅
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

  // 클라이언트 컴포넌트에 초기 데이터 전달
  return <VoteListClient 
    initialVotes={formattedVotes} 
    initialStatus={initialStatus || VOTE_STATUS.ONGOING} 
    initialArea={initialArea || VOTE_AREAS.KPOP} 
  />;
}

/**
 * 투표 목록 서버 컴포넌트
 * 
 * 서버에서 데이터를 가져와 클라이언트 컴포넌트로 전달합니다.
 * Suspense를 사용하여 로딩 상태를 처리합니다.
 */
export default function VoteListServer({ 
  initialStatus = VOTE_STATUS.ONGOING,
  initialArea = VOTE_AREAS.KPOP
}: VoteListProps) {
  return (
    <Suspense fallback={<LoadingState message="투표 목록을 불러오는 중..." size="medium" />}>
      <VoteDataFetcher initialStatus={initialStatus} initialArea={initialArea} />
    </Suspense>
  );
} 