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
    redirect: false, // 리디렉션 비활성화 - 투표 항목 저장 후 직접 처리
    warnWhenUnsavedChanges: true,
  });
  const { resource } = useResource();
  return (
    <AuthorizePage resource='vote' action='create'>
      <Create
        breadcrumb={false}
        
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <VoteForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
