'use client';

import { RewardShow } from '../../components';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Reward } from '../../components/types';
import { useResource, useShow } from '@refinedev/core';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
export default function RewardShowPage() {
  const { queryResult } = useShow<Reward>({});
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
        <RewardShow record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
