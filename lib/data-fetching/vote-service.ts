/**
 * 투표 관련 데이터 서비스
 * 
 * 서버 컴포넌트에서 투표 데이터를 조회하는 서비스 함수들입니다.
 * 각 함수는 React의 cache를 사용하여 요청을 캐싱합니다.
 */

import { cache } from 'react';
import { createClient } from '@/utils/supabase-server-client';
import { CacheOptions } from './fetchers';
import { Vote } from '@/types/interfaces';

// 기본 투표 테이블 조회 쿼리 (서버 컴포넌트용)
const DEFAULT_VOTE_QUERY = `
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
`;

/**
 * 투표 목록 조회 함수
 */
export const getVotes = cache(async (
  status?: string,
  area?: string,
  options?: CacheOptions
): Promise<Vote[]> => {
  const supabase = createClient();
  const now = new Date().toISOString();
  
  let query = supabase
    .from('vote')
    .select(DEFAULT_VOTE_QUERY)
    .is('deleted_at', null);

  // 상태별 필터링
  if (status) {
    if (status === 'upcoming') {
      query = query.gt('start_at', now);
    } else if (status === 'ongoing') {
      query = query.lte('start_at', now).gte('stop_at', now);
    } else if (status === 'completed') {
      query = query.lt('stop_at', now);
    }
  }

  // 영역별 필터링
  if (area) {
    query = query.eq('area', area);
  }

  // 정렬
  query = query.order('start_at', { ascending: false });
  
  const { data, error } = await query;
  
  if (error) {
    console.error('Vote fetch error:', error);
    throw new Error(error.message);
  }
  
  if (!data || data.length === 0) {
    return [];
  }
  
  // 응답 데이터 포맷팅
  return data.map((vote: any) => ({
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
});

/**
 * 투표 상세 조회 함수
 */
export const getVoteById = cache(async (
  id: string,
  options?: CacheOptions
): Promise<Vote | null> => {
  const supabase = createClient();
  
  const { data, error } = await supabase
    .from('vote')
    .select(DEFAULT_VOTE_QUERY)
    .eq('id', id)
    .is('deleted_at', null)
    .single();
  
  if (error) {
    if (error.code === 'PGRST116') {
      // 데이터가 없음
      return null;
    }
    console.error(`Vote ID ${id} fetch error:`, error);
    throw new Error(error.message);
  }
  
  if (!data) {
    return null;
  }
  
  // 응답 데이터 포맷팅
  return {
    ...data,
    deletedAt: data.deleted_at,
    startAt: data.start_at,
    stopAt: data.stop_at,
    createdAt: data.created_at,
    updatedAt: data.updated_at,
    mainImage: data.main_image,
    resultImage: data.result_image,
    waitImage: data.wait_image,
    voteCategory: data.vote_category,
    voteContent: data.vote_content,
    voteSubCategory: data.vote_sub_category,
    visibleAt: data.visible_at,
    area: data.area,
    voteItems: data.vote_item
      ? data.vote_item.map((item: any) => ({
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
    reward: data.vote_reward
      ? data.vote_reward.map((vr: any) => vr.reward).filter(Boolean)
      : [],
    title: data.title || '제목 없음',
  } as Vote;
}); 