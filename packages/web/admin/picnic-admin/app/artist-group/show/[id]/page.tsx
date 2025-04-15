'use client';

import { Show, EditButton, DeleteButton } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Typography, Skeleton, Space, Button, theme } from 'antd';
import { ArtistGroup } from '@/lib/types/artist';
import { useParams } from 'next/navigation';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupDetail from '@/app/artist-group/components/ArtistGroupDetail';

const { Title } = Typography;

export default function ArtistGroupShow() {
  // URL에서 id 파라미터 가져오기
  const params = useParams();
  const id = params?.id?.toString();

  const { queryResult } = useShow<ArtistGroup>({
    resource: 'artist_group',
    id: id,
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  const { show, edit, list } = useNavigation();
  const { resource } = useResource();
  const { token } = theme.useToken();

  if (isLoading) {
    return (
      <AuthorizePage resource='artist_group' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='artist_group' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <ArtistGroupDetail record={record} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
