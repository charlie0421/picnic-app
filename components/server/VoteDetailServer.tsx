import React, { Suspense } from 'react';
import { notFound } from 'next/navigation';
import { LoadingState } from '@/components/server';
import { getByIdOrNotFound, TABLES } from '@/lib/data-fetching/supabase-service';
import { createServerSupabaseClientWithRequest } from '@/lib/supabase/server';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { VoteDetailClient } from '@/components/client';

interface VoteDetailServerProps {
  id: string;
  req?: any;
  res?: any;
}

/**
 * 투표 상세 정보를 가져오는 컴포넌트
 */
async function VoteDetailData({ id, req, res }: VoteDetailServerProps) {
  try {
    // 페이지 라우터에서는 req/res가 필요함
    if (!req || !res) {
      console.warn('서버 컴포넌트에 req/res 객체가 전달되지 않았습니다. 인증 없는 클라이언트를 사용합니다.');
    }

    // req/res가 있으면 페이지 라우터용 클라이언트를 사용하고, 없으면 기본 클라이언트를 사용합니다
    const supabase = req && res 
      ? createServerSupabaseClientWithRequest(req, res)
      : createServerSupabaseClientWithRequest({ cookies: {} }, { setHeader: () => {} });

    const numericId = parseInt(id, 10);
    if (isNaN(numericId)) {
      throw new Error('유효하지 않은 ID 형식입니다.');
    }

    const { data: voteData, error } = await supabase
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
      .eq('id', numericId)
      .is('deleted_at', null)
      .single();

    if (error) {
      console.error('Vote fetch error:', error);
      if (error.code === 'PGRST116') {
        notFound();
      }
      throw new Error(`투표 데이터를 불러오는데 문제가 발생했습니다: ${error.message}`);
    }

    if (!voteData) {
      notFound();
    }

    // 투표 데이터 포맷팅
    const formattedVote: Vote = {
      id: voteData.id,
      order: 0, // 기본값 설정 (Vote 인터페이스 요구사항)
      area: voteData.area || '', // Vote 인터페이스 요구사항
      deletedAt: voteData.deleted_at,
      startAt: voteData.start_at,
      stopAt: voteData.stop_at,
      createdAt: voteData.created_at,
      updatedAt: voteData.updated_at,
      mainImage: voteData.main_image,
      resultImage: voteData.result_image,
      waitImage: voteData.wait_image,
      voteCategory: voteData.vote_category,
      voteContent: voteData.vote_content,
      voteSubCategory: voteData.vote_sub_category,
      visibleAt: voteData.visible_at,
      title: voteData.title || '제목 없음',
    };

    // 투표 항목 포맷팅
    const formattedVoteItems: VoteItem[] = voteData.vote_item
      ? voteData.vote_item.map((item: any) => ({
          id: item.id,
          deletedAt: item.deleted_at,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
          voteId: item.vote_id,
          artistId: item.artist_id,
          groupId: item.group_id || 0,
          voteTotal: item.vote_total || 0,
          artist: item.artist
            ? {
                id: item.artist.id,
                name: item.artist.name,
                image: item.artist.image,
                artistGroup: item.artist.artist_group
                  ? {
                      id: item.artist.artist_group.id,
                      name: item.artist.artist_group.name
                    }
                  : undefined
              }
            : undefined
        }))
      : [];

    // 보상 포맷팅
    const formattedRewards: Reward[] = voteData.vote_reward
      ? voteData.vote_reward
          .map((vr: any) => vr.reward)
          .filter(Boolean)
          .map((reward: any) => ({
            id: reward.id,
            createdAt: reward.created_at,
            updatedAt: reward.updated_at,
            deletedAt: reward.deleted_at,
            order: reward.order || 0,
            title: reward.name,
            description: reward.description,
            thumbnail: reward.image,
            overviewImages: reward.overview_images || [],
            locationImages: reward.location_images || [],
            location: reward.location,
            sizeGuide: reward.size_guide,
            sizeGuideImages: reward.size_guide_images || []
          }))
      : [];

    // 투표 상태 계산
    const now = new Date();
    const startDate = new Date(voteData.start_at);
    const endDate = new Date(voteData.stop_at);
    
    let voteStatus: 'upcoming' | 'ongoing' | 'ended' = 'upcoming';
    if (now < startDate) {
      voteStatus = 'upcoming';
    } else if (now < endDate) {
      voteStatus = 'ongoing';
    } else {
      voteStatus = 'ended';
    }

    // 클라이언트 컴포넌트에 데이터 전달
    return (
      <VoteDetailClient 
        id={id} 
        initialData={{
          vote: formattedVote,
          voteItems: formattedVoteItems,
          rewards: formattedRewards,
          voteStatus
        }}
      />
    );
  } catch (error) {
    if (error instanceof Error) {
      console.error('Vote detail error:', error);
      throw error;
    }
    notFound();
  }
}

/**
 * 투표 상세 서버 컴포넌트
 * 
 * 서버에서 투표 상세 데이터를 가져와 클라이언트 컴포넌트로 전달합니다.
 * Suspense를 사용하여 로딩 상태를 처리합니다.
 */
export default function VoteDetailServer({ id, req, res }: VoteDetailServerProps) {
  return (
    <Suspense fallback={<LoadingState message="투표 정보를 불러오는 중..." size="medium" fullPage />}>
      <VoteDetailData id={id} req={req} res={res} />
    </Suspense>
  );
}
