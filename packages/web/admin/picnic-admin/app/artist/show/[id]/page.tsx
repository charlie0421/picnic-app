'use client';

import { Show, DeleteButton } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Typography, Skeleton, Space, Button, theme } from 'antd';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import { Artist } from '@/lib/types/artist';
import ArtistDetail from '@/app/artist/components/ArtistDetail';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title } = Typography;

export default function ArtistShow() {
  const { queryResult } = useShow<Artist>({
    resource: 'artist',
    meta: {
      select: '*',
    },
  });

  const { data, isLoading } = queryResult;
  const { edit, list } = useNavigation();
  const id = data?.data?.id;
  const { resource } = useResource();
  const { token } = theme.useToken();

  if (isLoading) {
    return (
      <AuthorizePage resource='artist' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='artist' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
      >
        <div
          style={{
            marginBottom: '16px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <Space>
            <Button icon={<ArrowLeftOutlined />} onClick={() => list('artist')}>
              목록으로
            </Button>
            <Title level={5} style={{ margin: 0 }}>
              아티스트 정보
            </Title>
          </Space>
          <Space>
            <Button
              type='primary'
              icon={<EditOutlined />}
              onClick={() => edit('artist', id!)}
            >
              편집
            </Button>
            <DeleteButton recordItemId={id} onSuccess={() => list('artist')} />
          </Space>
        </div>

        <ArtistDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
