'use client';

import { Show } from '@refinedev/antd';
import { useShow, useResource } from '@refinedev/core';
import { message, Skeleton, Typography } from 'antd';
import BannerForm from '@/app/banner/components/BannerForm';
import { Banner } from '@/lib/types/banner';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import BannerDetail from '@/app/banner/components/BannerDetail';

export default function BannerShow({ params }: { params: { id: string } }) {
  const { queryResult } = useShow<Banner>({
    resource: 'banner',
    id: params.id,
    meta: {
      select: '*',
    },
  });
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='banner' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  console.log(data);

  return (
    <AuthorizePage resource='banner' action='show'>
      <Show
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.show?.label}
        isLoading={queryResult?.isLoading}
        canDelete={true}
      >
        <BannerDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
