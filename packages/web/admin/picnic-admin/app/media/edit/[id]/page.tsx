'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useState, useEffect } from 'react';
import MediaForm from '../../components/MediaForm';
import { useParams } from 'next/navigation';
import { useResource } from '@refinedev/core';

export default function MediaEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const [initialDataLoaded, setInitialDataLoaded] = useState<boolean>(false);

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'media',
    id,
    meta: {
      select: '*',
    },
  });

  const isLoading = queryResult?.isLoading;
  const isError = queryResult?.isError;
  const mediaData = queryResult?.data?.data;

  // 초기 데이터 설정
  useEffect(() => {
    if (mediaData && !initialDataLoaded) {
      setInitialDataLoaded(true);
    }
  }, [mediaData, initialDataLoaded]);

  const { resource } = useResource();

  // 데이터 로딩 중이면 로딩 표시
  if (isLoading) {
    return (
      <Edit title='미디어 수정'>
        <div style={{ textAlign: 'center', padding: '50px' }}>
          <Spin tip='데이터를 불러오는 중...' />
        </div>
      </Edit>
    );
  }

  // 데이터 로드 실패 시 에러 메시지
  if (isError) {
    return (
      <Edit title='미디어 수정'>
        <div style={{ textAlign: 'center', padding: '50px', color: 'red' }}>
          데이터를 불러오는 중 오류가 발생했습니다.
        </div>
      </Edit>
    );
  }


  return (
    <Edit
      breadcrumb={false}
      goBack={false}
      title={resource?.meta?.edit?.label}
      saveButtonProps={saveButtonProps}
    >
      {contextHolder}
      <MediaForm
        mode='edit'
        id={id}
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Edit>
  );
}
