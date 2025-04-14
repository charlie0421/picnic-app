'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useEffect, useState } from 'react';
import { useNavigation } from '@refinedev/core';
import { VoteItem } from '@/lib/types/vote';
import { VoteRecord, ApiResponse } from '@/lib/vote';
import VoteForm from '@/app/vote/components/VoteForm';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function VoteEdit({ params }: { params: { id: string } }) {
  const { push } = useNavigation();
  const [messageApi, contextHolder] = message.useMessage();
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);
  const [initialRewardIds, setInitialRewardIds] = useState<number[]>([]);

  // useForm을 통해 직접 데이터 로드
  const { formProps, saveButtonProps, queryResult } = useForm<VoteRecord>({
    redirect: 'show', // 저장 후 show 페이지로 리다이렉션
    warnWhenUnsavedChanges: true,
    queryOptions: {
      enabled: !!params.id,
    },
    resource: 'vote',
    id: params.id,
    action: 'edit',
    meta: {
      select: `*, vote_item(*, artist(*)), vote_reward(*, reward(*))`
    }
  });

  // queryResult로부터 받은 데이터를 이용하여 컴포넌트 상태 초기화
  useEffect(() => {
    if (queryResult?.data?.data) {
      const voteData = queryResult.data.data;
      
      // 투표 항목 초기화
      const voteItemsData = voteData.vote_item ?? [];
      setVoteItems(
        voteItemsData.map((item) => ({
          ...item,
          temp_id: item.id, // 기존 항목은 DB ID를 임시 ID로 사용
          is_existing: true, // 기존 항목 표시
        }))
      );

      // 리워드 ID 초기화
      const voteRewardData = voteData.vote_reward ?? [];
      console.log('useForm에서 가져온 vote_reward 데이터:', voteRewardData);
      
      if (voteRewardData.length > 0) {
        // vote_id가 현재 투표 ID와 일치하는 항목만 필터링
        const filteredRewards = voteRewardData.filter(
          (item: { vote_id: number | string }) => Number(item.vote_id) === Number(params.id)
        );
        console.log('현재 투표 ID에 해당하는 vote_reward 데이터:', filteredRewards);
        
        // 고유한 reward_id 추출
        const uniqueRewardIds = Array.from(new Set(
          filteredRewards
            .filter((item: { reward_id?: number | string }) => 
              item.reward_id && (typeof item.reward_id === 'number' || typeof item.reward_id === 'string'))
            .map((item: { reward_id: number | string }) => Number(item.reward_id))
            .filter((id: number) => !isNaN(id) && id > 0)
        )) as number[];
        
        console.log('추출된 고유 리워드 ID 목록:', uniqueRewardIds);
        setInitialRewardIds(uniqueRewardIds);
      }
    }
  }, [queryResult?.data, params.id]);

  // Refine에서 제공하는 saveButtonProps 확장하기
  const customSaveButtonProps = {
    ...saveButtonProps,
    onClick: () => {
      // 폼 데이터에서 임시 필드 제거 확인
      try {
        if (formProps.form) {
          const allValues = formProps.form.getFieldsValue(true);
          console.log('현재 폼 데이터 (제출 전):', allValues);
          
          // 임시 필드 확인
          const hasRewardFields = allValues._rewardIds || allValues._targetKeys;
          if (hasRewardFields) {
            console.log('임시 리워드 필드 감지됨 - 제출 전 정리');
            
            // 리워드 정보는 따로 저장 (VoteForm.tsx에서 사용)
            const rewardIds = allValues._rewardIds;
            
            // 폼 제출 전에 리워드 ID 필드 제거
            const { _rewardIds, _targetKeys, ...cleanValues } = allValues;
            
            // Form submit을 준비하는 (내부에서만 사용되는) 함수
            // (주의: 실제 API 호출 시에는 원본 form.submit()이 처리함)
            formProps.form.setFieldsValue(cleanValues);
            
            // 전역 window 객체에 임시 저장 (VoteForm 컴포넌트에서 접근할 수 있도록)
            // @ts-ignore
            window.__rewardIds = rewardIds;
          }
        }
      } catch (error) {
        console.error('폼 데이터 정리 중 오류:', error);
      }
      
      // form 제출
      formProps.form?.submit();
      
      // 원래 onClick이 있으면 호출
      if (typeof saveButtonProps.onClick === 'function') {
        saveButtonProps.onClick();
      }
    },
  };

  // 데이터 로딩 중이면 로딩 표시
  if (queryResult?.isLoading) {
    return (
      <AuthorizePage resource='vote' action='edit'>
        <Edit title='투표 수정'>
          <div style={{ textAlign: 'center', padding: '50px' }}>
            <Spin tip='데이터를 불러오는 중...' />
          </div>
        </Edit>
      </AuthorizePage>
    );
  }

  // 데이터 로드 실패 시 에러 메시지
  if (queryResult?.isError) {
    return (
      <AuthorizePage resource='vote' action='edit'>
        <Edit title='투표 수정'>
          <div style={{ textAlign: 'center', padding: '50px', color: 'red' }}>
            데이터를 불러오는 중 오류가 발생했습니다.
          </div>
        </Edit>
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='vote' action='edit'>
      <Edit 
        title='투표 수정'
        saveButtonProps={customSaveButtonProps} // 커스텀 saveButtonProps 전달
      >
        {contextHolder}
        <VoteForm
          mode="edit"
          id={params.id}
          initialVoteItems={voteItems}
          formProps={formProps}
          saveButtonProps={customSaveButtonProps} // 커스텀 saveButtonProps 전달
        />
      </Edit>
    </AuthorizePage>
  );
}
