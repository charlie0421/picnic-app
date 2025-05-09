'use client';

import { useResource, useShow } from '@refinedev/core';
import { type VoteRecord } from '@/lib/vote';
import VoteDetail from '@/app/vote/components/VoteDetail';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function VoteShow() {
  const { queryResult } = useShow<VoteRecord>({
    meta: {
      select:
        'id, title, main_image, vote_category, area, visible_at, start_at, stop_at, created_at, updated_at, deleted_at, vote_item(id, artist_id, vote_total, artist(id, name, image, birth_date, yy, mm, dd, artist_group(id, name, image, debut_yy, debut_mm, debut_dd)), created_at, updated_at, deleted_at)',
    },
  });
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
        <VoteDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
