'use client';

import { Show, DeleteButton, EditButton } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Media } from '@/lib/types/media';
import MediaDetail from '@/app/media/components/MediaDetail';

export default function MediaShow() {
  const { queryResult } = useShow<Media>({});
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
        <MediaDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
