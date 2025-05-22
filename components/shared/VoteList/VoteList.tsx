import React from 'react';
import { createClient } from '@/utils/supabase-server-client';
import { VoteListClient } from '@/components/client';
import { Vote } from '@/types/interfaces';
import { VOTE_STATUS, VOTE_AREAS } from '@/stores/voteFilterStore';

interface VoteListProps {
  initialStatus?: string;
  initialArea?: string;
}

export default async function VoteList({ 
  initialStatus = VOTE_STATUS.ONGOING,
  initialArea = VOTE_AREAS.KPOP
}: VoteListProps) {
  // 서버에서 초기 데이터 페칭
  const supabase = createClient();
  const now = new Date().toISOString();
  
  // 서버에서 필터링된 기본 투표 데이터 가져오기
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
  query = query.eq('area', initialArea);

  // 정렬
  query = query.order('start_at', { ascending: false });

  const { data: voteData, error: voteError } = await query;

  if (voteError) {
    console.error('Vote fetch error:', voteError);
    // 에러 처리는 클라이언트 컴포넌트에서 수행
    return <VoteListClient initialVotes={[]} initialStatus={initialStatus} initialArea={initialArea} error={voteError.message} />;
  }

  if (!voteData || voteData.length === 0) {
    // 데이터가 없는 경우 빈 배열 전달
    return <VoteListClient initialVotes={[]} initialStatus={initialStatus} initialArea={initialArea} />;
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
  return <VoteListClient initialVotes={formattedVotes} initialStatus={initialStatus} initialArea={initialArea} />;
} 