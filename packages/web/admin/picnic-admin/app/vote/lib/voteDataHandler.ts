import { createClient } from '@supabase/supabase-js';

// Supabase 클라이언트 생성
const supabaseClient = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
);

interface VoteItem {
  id?: number;
  vote_id: number;
  artist_id: number;
  deleted?: boolean;
}

interface VoteReward {
  vote_id: number;
  reward_id: number;
}

export interface VoteDataHandlerParams {
  voteId: number;
  currentVoteItems: any[];
  existingVoteItems?: any[];
  voteRewards: any[];
}

/**
 * vote_item 데이터 처리를 위한 유틸리티 함수
 */
export const handleVoteItems = async ({
  voteId,
  currentVoteItems,
  existingVoteItems = [],
}: VoteDataHandlerParams) => {
  try {
    // 1. 삭제된 아이템 처리
    const deletedItems = existingVoteItems.filter(
      (existingItem: any) =>
        !currentVoteItems.some(
          (currentItem: any) =>
            currentItem.id === existingItem.id && !currentItem.deleted,
        ),
    );

    // 2. 새로 추가된 아이템 처리
    const newItems = currentVoteItems.filter(
      (currentItem: any) =>
        !existingVoteItems.some(
          (existingItem: any) => existingItem.id === currentItem.id,
        ),
    );

    // 3. 수정된 아이템 처리
    const updatedItems = currentVoteItems.filter((currentItem: any) =>
      existingVoteItems.some(
        (existingItem: any) =>
          existingItem.id === currentItem.id &&
          !currentItem.deleted &&
          (existingItem.artist_id !== currentItem.artist_id ||
            existingItem.deleted !== currentItem.deleted),
      ),
    );

    // 삭제된 아이템 처리
    for (const item of deletedItems) {
      const { error: deleteError } = await supabaseClient
        .from('vote_item')
        .update({ deleted: true })
        .eq('id', item.id);

      if (deleteError) {
        console.error('투표 아이템 삭제 중 오류:', deleteError);
        throw deleteError;
      }
    }

    // 새로운 아이템 추가
    if (newItems.length > 0) {
      const { error: insertError } = await supabaseClient
        .from('vote_item')
        .insert(
          newItems.map((item: any) => ({
            vote_id: voteId,
            artist_id: item.artist_id,
            deleted: false,
          })),
        );

      if (insertError) {
        console.error('새 투표 아이템 추가 중 오류:', insertError);
        throw insertError;
      }
    }

    // 수정된 아이템 업데이트
    for (const item of updatedItems) {
      const { error: updateError } = await supabaseClient
        .from('vote_item')
        .update({
          artist_id: item.artist_id,
          deleted: item.deleted || false,
        })
        .eq('id', item.id);

      if (updateError) {
        console.error('투표 아이템 업데이트 중 오류:', updateError);
        throw updateError;
      }
    }

    return true;
  } catch (error) {
    console.error('투표 아이템 처리 중 오류:', error);
    throw error;
  }
};

/**
 * vote_reward 데이터 처리를 위한 유틸리티 함수
 */
export const handleVoteRewards = async ({
  voteId,
  voteRewards,
}: VoteDataHandlerParams) => {
  try {
    // 1. 기존 vote_reward 삭제
    const { error: deleteError } = await supabaseClient
      .from('vote_reward')
      .delete()
      .eq('vote_id', voteId);

    if (deleteError) {
      console.error('기존 리워드 삭제 중 오류:', deleteError);
      throw deleteError;
    }

    // 2. 새로운 vote_reward 추가
    if (voteRewards?.length > 0) {
      const newRewards = voteRewards.map((item: any) => ({
        vote_id: voteId,
        reward_id: item.reward_id,
      }));

      const { error: insertError } = await supabaseClient
        .from('vote_reward')
        .insert(newRewards);

      if (insertError) {
        console.error('새 리워드 추가 중 오류:', insertError);
        throw insertError;
      }
    }

    return true;
  } catch (error) {
    console.error('투표 리워드 처리 중 오류:', error);
    throw error;
  }
};

/**
 * 투표 관련 데이터를 모두 처리하는 메인 핸들러
 */
export const handleVoteData = async (params: VoteDataHandlerParams) => {
  try {
    // vote_item 처리
    await handleVoteItems(params);

    // vote_reward 처리
    await handleVoteRewards(params);

    return true;
  } catch (error) {
    console.error('투표 데이터 처리 중 오류:', error);
    throw error;
  }
};
