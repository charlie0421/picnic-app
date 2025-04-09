'use client';

import { Show, DateField } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Typography, Space } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title, Text } = Typography;

export default function UserRoleShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();

  return (
    <AuthorizePage resource='admin_user_roles' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
      <Title level={5}>사용자 역할 ID</Title>
        <Text>{record?.id}</Text>

        <Title level={5}>사용자 ID</Title>
        <Text>{record?.user_id}</Text>

        <Title level={5}>역할 ID</Title>
        <Text>{record?.role_id}</Text>

        <Title level={5}>생성일/수정일</Title>
        <Space direction="vertical">
          <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
          <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </Space>
      </Show>
    </AuthorizePage>
  );
}
