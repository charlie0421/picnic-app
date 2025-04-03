'use client';

import { Create, useForm } from '@refinedev/antd';
import { useNavigation, useCreate } from '@refinedev/core';
import { useState } from 'react';
import { message } from 'antd';
import VoteForm from '@/components/vote/VoteForm';
import { VoteRecord } from '@/utils/vote';

export default function VoteCreate() {
  const { push } = useNavigation();
  const [messageApi, contextHolder] = message.useMessage();

  // 폼 정의
  const { formProps, saveButtonProps } = useForm<VoteRecord>({
    redirect: false, // 리디렉션 비활성화 - 투표 항목 저장 후 직접 처리
    warnWhenUnsavedChanges: true,
  });

  return (
    <Create title='투표 생성'>
      {contextHolder}
      <VoteForm
        mode='create'
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Create>
  );
}
