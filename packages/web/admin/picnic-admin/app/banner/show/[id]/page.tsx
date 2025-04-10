'use client';

import { Show } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Skeleton, Space, Button, Typography } from 'antd';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import BannerDetail from '@/app/banner/components/BannerDetail';
import { Banner } from '@/lib/types/banner';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title } = Typography;

export default function BannerShow() {
  const { queryResult } = useShow<Banner>({
    resource: 'banner',
    meta: {
      select: '*',
    },
  });
  const { data, isLoading } = queryResult;
  const { edit, list } = useNavigation();
  const id = data?.data?.id;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='banner' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='banner' action='show'>
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
            <Button icon={<ArrowLeftOutlined />} onClick={() => list('banner')}>
              목록으로
            </Button>
            <Title level={5} style={{ margin: 0 }}>
              배너 정보
            </Title>
          </Space>
          <Space>
            <Button
              type='primary'
              icon={<EditOutlined />}
              onClick={() => edit('banner', id!)}
            >
              편집
            </Button>
            <Button
              danger
              icon={<DeleteOutlined />}
              onClick={() => {
                // TODO: 삭제 기능 구현
              }}
            >
              삭제
            </Button>
          </Space>
        </div>
        <BannerDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
