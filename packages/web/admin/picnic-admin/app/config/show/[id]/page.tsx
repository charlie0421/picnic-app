'use client';

import { useResource, useShow } from '@refinedev/core';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ConfigDetail from '@/app/config/components/ConfigDetail';

export default function ConfigShow() {
  const { queryResult } = useShow<Config>({});
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
        <ConfigDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
