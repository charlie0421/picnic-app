import { supabaseBrowserClient } from '@/lib/supabase/client';

interface VoteItem {
  id?: number;
  vote_id: number;
  artist_id: number;
  deleted_at?: string | null;
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
    // 기존 항목이 없고 현재 항목도 없으면 바로 종료
    if (
      existingVoteItems.length === 0 &&
      (!currentVoteItems || currentVoteItems.length === 0)
    ) {
      return true;
    }

    // 현재 항목이 없는 경우 빈 배열로 초기화
    const processedCurrentItems = currentVoteItems || [];

    // artist_id가 문자열인 경우 숫자로 변환 (모든 항목에 대해)
    const normalizedCurrentItems = processedCurrentItems.map((item: any) => {
      let artistId = item.artist_id;
      if (typeof artistId === 'string') {
        artistId = parseInt(artistId, 10);
        if (isNaN(artistId)) {
          artistId = 0; // 기본값 설정
        }
      }

      return {
        ...item,
        artist_id: artistId,
      };
    });

    // 1. 삭제된 아이템 처리 - 모든 기존 항목 중에서 현재 항목 목록에 없거나 deleted_at이 설정된 항목
    const deletedItems = existingVoteItems.filter((existingItem: any) => {
      // 기존 아이템이 삭제된 경우(deleted_at이 이미 있는 경우)는 건너뜀
      if (existingItem.deleted_at) {
        return false;
      }

      // 현재 목록에 해당 ID를 가진 항목이 없거나, 있어도 deleted_at이 설정된 경우 삭제로 처리
      const currentItem = normalizedCurrentItems.find(
        (item: any) =>
          item.id &&
          existingItem.id &&
          item.id.toString() === existingItem.id.toString(),
      );

      // 현재 목록에 없으면 삭제된 것으로 간주
      if (!currentItem) {
        return true;
      }

      // 현재 목록에 있지만 deleted_at이 설정된 경우 삭제된 것으로 간주
      if (currentItem.deleted_at) {
        return true;
      }

      return false;
    });

    // 2. 새로 추가된 아이템 처리 - temp_id가 있거나 id가 없거나, 기존 목록에 없는 ID를 가진 항목
    const newItems = normalizedCurrentItems.filter((currentItem: any) => {
      // 이미 deleted_at이 설정된 아이템은 추가하지 않음
      if (currentItem.deleted_at) {
        return false;
      }

      // temp_id만 있거나 id가 없는 경우 (새 아이템)
      if (
        !currentItem.id ||
        (currentItem.temp_id &&
          !existingVoteItems.some(
            (existingItem: any) =>
              existingItem.id &&
              existingItem.id.toString() === currentItem.id?.toString(),
          ))
      ) {
        return true;
      }

      return false;
    });

    // 3. 수정된 아이템 처리 - 기존 목록과 현재 목록에 모두 있으면서 artist_id가 변경된 항목
    const updatedItems = normalizedCurrentItems.filter((currentItem: any) => {
      // id가 없는 경우 (새 항목) 업데이트 대상 아님
      if (!currentItem.id) return false;

      // deleted_at이 설정된 아이템은 업데이트 목록에서 제외 (삭제 대상)
      if (currentItem.deleted_at) return false;

      // 기존 항목 중에서 같은 id를 가진 항목 찾기
      const matchingItem = existingVoteItems.find(
        (existingItem: any) =>
          existingItem.id &&
          currentItem.id &&
          existingItem.id.toString() === currentItem.id.toString() &&
          !existingItem.deleted_at,
      );

      // 매칭되는 항목이 없으면 업데이트 대상 아님 (새 항목)
      if (!matchingItem) return false;

      // artist_id가 변경된 경우만 업데이트 대상
      if (matchingItem.artist_id !== currentItem.artist_id) {
        return true;
      }

      return false;
    });

    // 삭제된 아이템 처리 - 직접 데이터베이스에 삭제 명령 전송
    if (deletedItems.length > 0) {
      for (const item of deletedItems) {
        const { error: deleteError } = await supabaseBrowserClient
          .from('vote_item')
          .update({
            deleted_at: new Date().toISOString(),
          })
          .eq('id', item.id);

        if (deleteError) {
          throw deleteError;
        }
      }
    }

    // 새로운 아이템 추가
    if (newItems.length > 0) {
      const insertData = newItems.map((item: any) => ({
        vote_id: voteId,
        artist_id: item.artist_id,
        deleted_at: null,
      }));

      const { error: insertError } = await supabaseBrowserClient
        .from('vote_item')
        .insert(insertData);

      if (insertError) {
        throw insertError;
      }
    }

    // 수정된 아이템 업데이트
    if (updatedItems.length > 0) {
      for (const item of updatedItems) {
        const { error: updateError } = await supabaseBrowserClient
          .from('vote_item')
          .update({ artist_id: item.artist_id })
          .eq('id', item.id);

        if (updateError) {
          throw updateError;
        }
      }
    }

    return true;
  } catch (error) {
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
    // 빈 배열인 경우 기본값 설정
    const processedRewards = voteRewards || [];

    // 1. 기존 데이터 불러오기
    const { data: existingRewards, error: fetchError } =
      await supabaseBrowserClient
        .from('vote_reward')
        .select('vote_id, reward_id')
        .eq('vote_id', voteId);

    if (fetchError) {
      throw fetchError;
    }

    // 2. 먼저 vote_achieve 테이블의 연관된 데이터를 확인하고 처리
    if (existingRewards && existingRewards.length > 0) {
      // 각 리워드 ID에 대해 vote_achieve 테이블에 연관된 데이터가 있는지 확인
      for (const reward of existingRewards) {
        // vote_achieve 테이블에서 해당 리워드를 참조하는 레코드 조회
        const { data: achieveData, error: achieveError } =
          await supabaseBrowserClient
            .from('vote_achieve')
            .select('id')
            .eq('reward_id', reward.reward_id);

        if (achieveError) {
          throw achieveError;
        }

        // 연관된 vote_achieve 레코드가 있으면 먼저 삭제 또는 업데이트
        if (achieveData && achieveData.length > 0) {
          const achieveIds = achieveData.map((item) => item.id);

          // vote_achieve 레코드 삭제 또는 null로 업데이트
          const { error: achieveUpdateError } = await supabaseBrowserClient
            .from('vote_achieve')
            .update({ reward_id: null }) // null로 설정하거나 삭제, 스키마에 따라 결정
            .in('id', achieveIds);

          if (achieveUpdateError) {
            throw achieveUpdateError;
          }
        }
      }

      // 3. 기존 vote_reward 데이터 삭제
      const { error: deleteError } = await supabaseBrowserClient
        .from('vote_reward')
        .delete()
        .eq('vote_id', voteId);

      if (deleteError) {
        throw deleteError;
      }
    }

    // 4. 새로운 데이터 삽입 (있는 경우)
    if (processedRewards.length > 0) {
      const rewardInsertData = processedRewards.map((reward: any) => ({
        vote_id: voteId,
        reward_id:
          typeof reward.reward_id === 'string'
            ? parseInt(reward.reward_id, 10)
            : reward.reward_id,
      }));

      const { error: insertError } = await supabaseBrowserClient
        .from('vote_reward')
        .insert(rewardInsertData);

      if (insertError) {
        throw insertError;
      }
    }

    return true;
  } catch (error) {
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
    throw error;
  }
};
