'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import BannerDetail from '@/app/banner/components/BannerDetail';
import { Banner } from '@/lib/types/banner';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function BannerShow() {
  const { queryResult } = useShow<Banner>({});
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  return (
    <AuthorizePage action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <BannerDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
