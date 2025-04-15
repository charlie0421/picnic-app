'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
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
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <BannerDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
