'use client';

import { useShow, useNavigation, useResource } from '@refinedev/core';
import { type VoteRecord } from '@/lib/vote';
import VoteDetail from '@/app/vote/components/VoteDetail';
import { Typography, Skeleton, Space, Button } from 'antd';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title } = Typography;

export default function VoteShow({ params }: { params: { id: string } }) {
  const { queryResult } = useShow<VoteRecord>({
    resource: 'vote',
    id: params.id,
    meta: {
      select:
        'id, title, main_image, vote_category, visible_at, start_at, stop_at, created_at, updated_at, deleted_at, vote_item(id, artist_id, vote_total, artist(id, name, image, birth_date, yy, mm, dd, artist_group(id, name, image, debut_yy, debut_mm, debut_dd)), created_at, updated_at, deleted_at)',
    },
  });
  const { data, isLoading } = queryResult;
  const { edit, list } = useNavigation();
  const id = params.id;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='vote' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='vote' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.label}
        canEdit
        canDelete
      >
        <VoteDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
