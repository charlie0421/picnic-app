'use client';

import { useShow, useNavigation } from '@refinedev/core';
import { type VoteRecord } from '@/utils/vote';
import VoteDetail from '@/components/vote/VoteDetail';
import { Typography, Skeleton, Space, Button } from 'antd';
import { DeleteButton } from '@refinedev/antd';
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

  if (isLoading) {
    return (
      <AuthorizePage resource='vote' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='vote' action='show'>
      <div>
        <div
          style={{
            marginBottom: '16px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <Space>
            <Button icon={<ArrowLeftOutlined />} onClick={() => list('vote')}>
              목록으로
            </Button>
            <Title level={5} style={{ margin: 0 }}>
              투표 상세
            </Title>
          </Space>
          <Space>
            <Button
              type='primary'
              icon={<EditOutlined />}
              onClick={() => edit('vote', id)}
            >
              편집
            </Button>
            <DeleteButton
              resource='vote'
              recordItemId={id}
              onSuccess={() => list('vote')}
            />
          </Space>
        </div>
        <VoteDetail record={data?.data} loading={isLoading} />
      </div>
    </AuthorizePage>
  );
}
