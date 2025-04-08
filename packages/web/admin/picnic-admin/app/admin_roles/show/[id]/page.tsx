'use client';

import { Show, DateField, EditButton } from '@refinedev/antd';
import { Typography } from 'antd';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource, useShow } from '@refinedev/core';

const { Title, Text } = Typography;

export default function RoleShow(params: { params: { id: string } }) {
  const { queryResult } = useShow<AdminRole>({
    resource: 'admin_roles',
    id: params.params.id,
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();

  console.log(resource);

  return (
    <AuthorizePage resource='admin_roles' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.label}
      >
        <Title level={5}>ID</Title>
        <Text>{record?.id}</Text>

        <Title level={5}>역할 이름</Title>
        <Text>{record?.name}</Text>

        <Title level={5}>설명</Title>
        <Text>{record?.description}</Text>

        <Title level={5}>생성일</Title>
        <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
          
        <Title level={5}>수정일</Title>
        <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
      </Show>
    </AuthorizePage>
  );
}
