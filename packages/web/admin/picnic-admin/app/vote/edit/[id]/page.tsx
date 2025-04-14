'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useEffect } from 'react';
import { useNavigation } from '@refinedev/core';
import { VoteRecord } from '@/lib/vote';
import VoteForm from '@/app/vote/components/VoteForm';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function VoteEdit({ params }: { params: { id: string } }) {
  const { push } = useNavigation();
  const [messageApi, contextHolder] = message.useMessage();
  
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

  console.log('useForm에서 생성된 formProps:', formProps);
  
  // queryResult로부터 받은 데이터를 이용한 로깅 (디버깅용)
  useEffect(() => {
    if (queryResult?.data?.data) {
      const voteData = queryResult.data.data;
      console.log('투표 데이터 로드됨:', voteData);
      
      // 리워드 데이터 로깅
      const voteRewardData = voteData.vote_reward ?? [];
      if (voteRewardData.length > 0) {
        console.log('vote_reward 데이터:', voteRewardData);
        
        // 현재 투표 ID와 일치하는 리워드 데이터 필터링
        const filteredRewards = voteRewardData.filter(
          (item: any) => Number(item.vote_id) === Number(params.id)
        );
        
        console.log('현재 투표 ID의 리워드 데이터:', filteredRewards);
        
        // 고유 리워드 ID 추출
        const rewardIds = Array.from(new Set(
          filteredRewards
            .filter((item: any) => item.reward_id)
            .map((item: any) => Number(item.reward_id))
            .filter((id: number) => !isNaN(id) && id > 0)
        ));
        
        console.log('이 투표의 리워드 ID 목록:', rewardIds);
      }
    }
  }, [queryResult?.data, params.id]);

  // saveButtonProps 커스터마이징 - 리워드 ID 처리 로직 추가
  const customSaveButtonProps = {
    ...saveButtonProps,
    onClick: () => {
      try {
        if (formProps.form) {
          const allValues = formProps.form.getFieldsValue(true);
          console.log('현재 폼 데이터 (제출 전):', allValues);
          
          // 임시 필드 확인 및 처리
          const hasRewardFields = allValues._rewardIds || allValues._targetKeys;
          if (hasRewardFields) {
            console.log('임시 리워드 필드 감지됨 - 제출 전 정리');
            
            // 폼 제출 전에 리워드 ID 필드 제거
            const { _rewardIds, _targetKeys, ...cleanValues } = allValues;
            formProps.form.setFieldsValue(cleanValues);
          }
        }
        
        // 원래 saveButtonProps.onClick 호출
        saveButtonProps.onClick?.();
      } catch (error) {
        console.error('폼 데이터 정리 중 오류:', error);
        // 폼 정리에 실패해도 원래 버튼 클릭 동작은 수행
        saveButtonProps.onClick?.();
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
        saveButtonProps={customSaveButtonProps}
      >
        {contextHolder}
        <VoteForm
          mode="edit"
          id={params.id}
          formProps={formProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
