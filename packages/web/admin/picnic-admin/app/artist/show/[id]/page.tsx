'use client';

import { Show, DeleteButton } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import {
  Typography,
  Skeleton,
  Space,
  Button,
} from 'antd';
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
  // URL에서 id 파라미터 가져오기
  const { queryResult } = useShow<Artist>({
    resource: 'artist',
    meta: {
      select:
        'id, name, image, yy, mm, dd, gender, group_id, birth_date, debut_yy, debut_mm, debut_dd, created_at, updated_at',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;
  const id = record?.id;

  const { edit, list } = useNavigation();
  const { resource } = useResource();

  if (isLoading) {
    return <Skeleton active paragraph={{ rows: 10 }} />;
  }

  return (
    <AuthorizePage resource="artist" action="show">
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
            <DeleteButton
              resource='artist'
              recordItemId={id}
              onSuccess={() => list('artist')}
            />
          </Space>
        </div>
        
        <ArtistDetail record={record} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
