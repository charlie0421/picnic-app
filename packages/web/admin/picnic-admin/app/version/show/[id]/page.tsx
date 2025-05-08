'use client';

import { useShow, useResource } from '@refinedev/core';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Version } from '@/lib/types/version';
import VersionDetail from '../../components/VersionDetail';

export default function VersionShow() {
  const { queryResult } = useShow<Version>({
    resource: 'version',
  });
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  return (
    <AuthorizePage resource='version' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <VersionDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
