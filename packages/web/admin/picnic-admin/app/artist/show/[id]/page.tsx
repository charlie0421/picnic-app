'use client';

import { Show, DeleteButton, EditButton } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Artist } from '@/lib/types/artist';
import ArtistDetail from '@/app/artist/components/ArtistDetail';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ArtistShow() {
  const { queryResult } = useShow<Artist>({});
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
        <ArtistDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
