'use client';

import { Show } from '@refinedev/antd';
import { useShow, useResource } from '@refinedev/core';
import { message, Typography } from 'antd';
import BannerForm from '@/app/banner/components/BannerForm';
import { Banner } from '@/lib/types/banner';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import BannerDetail from '@/app/banner/components/BannerDetail';

export default function BannerShow() {
  const { queryResult } = useShow<Banner>();
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  return (
    <AuthorizePage resource='banner' action='show'>
      <Show
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.show?.label}
        isLoading={queryResult?.isLoading}
      >
        {contextHolder}
        <BannerDetail record={queryResult?.data?.data} loading={queryResult?.isLoading} />
        
      </Show>
    </AuthorizePage>
  );
}
