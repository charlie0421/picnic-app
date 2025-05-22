import React, { Suspense } from 'react';
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { VoteDetailClient } from '@/components/client';
import LoadingState from './LoadingState';

interface VoteDetailServerProps {
  id: string;
}

// Supabase 응답에서 가져온 데이터를 위한 간소화된 인터페이스들
interface VoteDataItem {
  id: number;
  vote_id: number;
  artist_id: number | null;
  group_id: number | null;
  vote_total: number;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  artist: {
    id: number;
    name: string | { [lang: string]: string };
    image: string | null;
    artist_group?: {
      id: number;
      name: string | { [lang: string]: string };
    } | null;
  } | null;
}

// 실제 데이터를 페칭하는 내부 컴포넌트
async function VoteDetailData({ id }: VoteDetailServerProps) {
  try {
    // 서버에서 데이터 페칭
    const supabase = createServerSupabaseClient();
    
    // ID를 숫자로 변환
    const numericId = parseInt(id, 10);
    if (isNaN(numericId)) {
      throw new Error('유효하지 않은 ID 형식입니다.');
    }
    
    // 투표 데이터 가져오기
    const { data: voteData, error: voteError } = await supabase
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
      
    if (voteError) {
      throw voteError;
    }
    
    // 데이터 포맷팅
    const formattedVote: Vote = {
      id: voteData.id,
      order: 0, // 인터페이스에 필요한 기본값 설정
      area: '', // 인터페이스에 필요한 기본값 설정
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
    
    const formattedVoteItems: VoteItem[] = voteData.vote_item
      ? voteData.vote_item.map((item: VoteDataItem) => {
          const artistData = item.artist ? {
            id: item.artist.id,
            name: item.artist.name,
            image: item.artist.image,
            artistGroup: item.artist.artist_group 
              ? {
                  id: item.artist.artist_group.id,
                  name: item.artist.artist_group.name
                } 
              : undefined
          } : undefined;
          
          return {
            id: item.id,
            deletedAt: item.deleted_at,
            createdAt: item.created_at,
            updatedAt: item.updated_at,
            voteId: item.vote_id,
            artistId: item.artist_id,
            groupId: item.group_id || 0,
            voteTotal: item.vote_total || 0,
            artist: artistData as any
          } as VoteItem;
        })
      : [];
      
    const formattedRewards: Reward[] = voteData.vote_reward
      ? voteData.vote_reward
          .map((vr: any) => vr.reward)
          .filter(Boolean)
          .map((reward: any) => {
            return {
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
            } as Reward;
          })
      : [];
    
    // 투표 상태 계산
    const now = new Date();
    const startDate = new Date(formattedVote.startAt as string);
    const endDate = new Date(formattedVote.stopAt as string);
    
    let voteStatus: 'upcoming' | 'ongoing' | 'ended' = 'upcoming';
    if (now < startDate) {
      voteStatus = 'upcoming';
    } else if (now < endDate) {
      voteStatus = 'ongoing';
    } else {
      voteStatus = 'ended';
    }
    
    // 클라이언트 컴포넌트에 초기 데이터 전달
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
    console.error('투표 상세 데이터 로딩 오류:', error);
    
    // 오류 시 빈 데이터와 함께 클라이언트 컴포넌트 렌더링
    return (
      <div className="p-4 text-center">
        <p className="text-red-500 mb-4">데이터를 로드하는 중 오류가 발생했습니다.</p>
        <VoteDetailClient 
          id={id} 
          initialData={{
            vote: {
              id: parseInt(id, 10) || 0,
              title: '데이터 로드 오류',
              area: '',
              order: 0,
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString(),
              startAt: new Date().toISOString(),
              stopAt: new Date().toISOString(),
              voteCategory: '',
              voteContent: '데이터를 로드하는 중 오류가 발생했습니다.',
            } as Vote,
            voteItems: [],
            rewards: [],
            voteStatus: 'ended'
          }}
        />
      </div>
    );
  }
}

// 외부에서 사용하는 메인 컴포넌트 (Suspense 포함)
export default function VoteDetailServer({ id }: VoteDetailServerProps) {
  return (
    <Suspense fallback={<LoadingState message="투표 정보를 불러오는 중..." />}>
      <VoteDetailData id={id} />
    </Suspense>
  );
}
