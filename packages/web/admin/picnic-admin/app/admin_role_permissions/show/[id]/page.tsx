'use client';

import { Show, DateField } from '@refinedev/antd';
import { useNavigation, useResource, useShow } from '@refinedev/core';
import { Typography, Space } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title, Text } = Typography;

export default function RolePermissionShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();
  return (
    <AuthorizePage resource='admin_role_permissions' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.label}
      >
      <Title level={5}>역할 권한 ID</Title>
        <Text>{record?.id}</Text>

        <Title level={5}>역할 ID</Title>
        <Text>{record?.role_id}</Text>

        <Title level={5}>권한 ID</Title>
        <Text>{record?.permission_id}</Text>

        <Title level={5}>생성일/수정일</Title>
        <Space direction="vertical">
          <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
          <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </Space>
      </Show>
    </AuthorizePage>
  );
}
