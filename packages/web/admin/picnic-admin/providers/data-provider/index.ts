'use client';

import { dataProvider as dataProviderSupabase } from '@refinedev/supabase';
import { supabaseBrowserClient } from '@/lib/supabase/client';
import { BaseKey, GetListResponse, DeleteOneResponse } from '@refinedev/core';

// 기본 Supabase 데이터 프로바이더 생성
const supabaseDataProvider = dataProviderSupabase(supabaseBrowserClient);

// 커스텀 데이터 프로바이더 - 기본 프로바이더 확장
export const dataProvider = {
  ...supabaseDataProvider,
  
  // delete 메서드 오버라이드
  deleteOne: async ({ 
    resource, 
    id, 
    meta 
  }: {
    resource: string;
    id: BaseKey;
    meta?: Record<string, unknown>;
  }): Promise<DeleteOneResponse<any>> => {
    // 투표 리소스인 경우 특별 처리
    if (resource === 'vote') {
      // 1. vote_achieve 테이블에서 관련 데이터 처리
      try {
        // 투표와 관련된 모든 vote_reward 조회
        const { data: voteRewards, error: voteRewardError } = await supabaseBrowserClient
          .from('vote_reward')
          .select('vote_id, reward_id')
          .eq('vote_id', id);
          
        if (voteRewardError) throw voteRewardError;
        
        if (voteRewards && voteRewards.length > 0) {
          // 연관된 리워드 ID 추출
          const rewardIds = voteRewards.map(item => item.reward_id);
          
          // vote_achieve 테이블에서 해당 리워드를 참조하는 레코드 조회 및 처리
          const { data: achieveData, error: achieveError } = await supabaseBrowserClient
            .from('vote_achieve')
            .select('id')
            .in('reward_id', rewardIds);
            
          if (achieveError) throw achieveError;
          
          if (achieveData && achieveData.length > 0) {
            // vote_achieve 레코드 업데이트 (reward_id = null)
            const { error: achieveUpdateError } = await supabaseBrowserClient
              .from('vote_achieve')
              .update({ reward_id: null })
              .in('id', achieveData.map(item => item.id));
              
            if (achieveUpdateError) throw achieveUpdateError;
          }
        }
        
        // 2. vote_item 삭제 (또는 업데이트)
        const { error: voteItemError } = await supabaseBrowserClient
          .from('vote_item')
          .update({ deleted_at: new Date().toISOString() })
          .eq('vote_id', id);
          
        if (voteItemError) throw voteItemError;
        
        // 3. vote_reward 삭제
        const { error: voteRewardDeleteError } = await supabaseBrowserClient
          .from('vote_reward')
          .delete()
          .eq('vote_id', id);
          
        if (voteRewardDeleteError) throw voteRewardDeleteError;
        
        // 4. 마지막으로 투표 자체 삭제
        const { data, error } = await supabaseBrowserClient
          .from(resource)
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', id)
          .select()
          .single();
          
        if (error) throw error;
        
        return {
          data,
        };
      } catch (error) {
        throw error;
      }
    }
    
    // 다른 리소스는 기본 deleteOne 메서드 사용
    return supabaseDataProvider.deleteOne({ resource, id, meta });
  },
};
