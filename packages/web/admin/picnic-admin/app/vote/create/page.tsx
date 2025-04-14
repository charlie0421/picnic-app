'use client';

import { Create, useForm } from '@refinedev/antd';
import { useNavigation, useCreate, useResource } from '@refinedev/core';
import { useState } from 'react';
import { message } from 'antd';
import VoteForm from '@/app/vote/components/VoteForm';
import { VoteRecord } from '@/lib/vote';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function VoteCreate() {
  const { push } = useNavigation();
  const [messageApi, contextHolder] = message.useMessage();

  // 폼 정의
  const { formProps, saveButtonProps } = useForm<VoteRecord>({
    redirect: 'show', // 저장 후 show 페이지로 리다이렉트
    warnWhenUnsavedChanges: true
  });

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
            const cleanValues = { ...allValues };
            delete cleanValues._rewardIds;
            delete cleanValues._targetKeys;
            
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

  const { resource } = useResource();
  return (
    <AuthorizePage resource='vote' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={customSaveButtonProps}
      >
        {contextHolder}
        <VoteForm
          mode='create'
          formProps={formProps}
          saveButtonProps={customSaveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
