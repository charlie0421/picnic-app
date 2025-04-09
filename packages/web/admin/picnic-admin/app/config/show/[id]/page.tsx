'use client';

import { useOne, useResource } from '@refinedev/core';
import { Show } from '@refinedev/antd';
import { Typography, Card } from 'antd';
import { useParams } from 'next/navigation';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title, Text } = Typography;

export default function ConfigShow() {
  const params = useParams();
  const id = params.id as string;

  const { data, isLoading } = useOne<Config>({
    resource: 'config',
    id,
  });

  const record = data?.data;
  const { resource } = useResource();
  return (
    <AuthorizePage resource='config' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
      <Card>
          <Title level={5}>키</Title>
          <Text>{record?.key}</Text>

          <Title level={5}>값</Title>
          <Text>{record?.value}</Text>

          <Title level={5}>생성일</Title>
          <Text>
            {record?.created_at && new Date(record.created_at).toLocaleString()}
          </Text>

          <Title level={5}>수정일</Title>
          <Text>
            {record?.updated_at && new Date(record.updated_at).toLocaleString()}
          </Text>
        </Card>
      </Show>
    </AuthorizePage>
  );
}
