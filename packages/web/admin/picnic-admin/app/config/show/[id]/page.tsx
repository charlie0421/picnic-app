'use client';

import { useOne, useResource } from '@refinedev/core';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { Skeleton } from 'antd';
import { useParams } from 'next/navigation';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ConfigDetail from '@/app/config/components/ConfigDetail';

export default function ConfigShow() {
  const params = useParams();
  const id = params.id as string;

  const { data, isLoading } = useOne<Config>({
    resource: 'config',
    id,
  });

  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='config' action='show'>
        <Skeleton active paragraph={{ rows: 5 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='config' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <ConfigDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
