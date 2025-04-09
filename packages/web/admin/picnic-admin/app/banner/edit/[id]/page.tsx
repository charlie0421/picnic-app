'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useState, useEffect } from 'react';
import BannerForm from '../../components/BannerForm';
import { useParams } from 'next/navigation';
import { useResource } from '@refinedev/core';
import { Banner } from '@/lib/types/banner';

export default function BannerEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const [initialDataLoaded, setInitialDataLoaded] = useState<boolean>(false);

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'banner',
    id,
    meta: {
      select: '*',
    },
  });

  const isLoading = queryResult?.isLoading;
  const isError = queryResult?.isError;
  const bannerData = queryResult?.data?.data;

  useEffect(() => {
    if (bannerData && !initialDataLoaded) {
      setInitialDataLoaded(true);
    }
  }, [bannerData, initialDataLoaded]);

  const { resource } = useResource();

  if (isLoading) {
    return (
      <Edit title='배너 수정'>
        <div style={{ textAlign: 'center', padding: '50px' }}>
          <Spin tip='데이터를 불러오는 중...' />
        </div>
      </Edit>
    );
  }

  if (isError) {
    return (
      <Edit title='배너 수정'>
        <div>데이터를 불러오는데 실패했습니다.</div>
      </Edit>
    );
  }

  return (
    <>
      {contextHolder}
      <Edit
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.edit?.label}
        resource='banner'
        saveButtonProps={{
          ...saveButtonProps,
          onClick: async () => {
            const values = await formProps.form?.validateFields();
            if (values) {
              formProps.onFinish?.(values);
            }
          },
        }}
      >
        <BannerForm
          mode='edit'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </>
  );
}
