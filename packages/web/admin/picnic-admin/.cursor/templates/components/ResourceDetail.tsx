'use client';

import React from 'react';
import { useShow, useResource } from '@refinedev/core';
import { Descriptions, message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { DeleteButton, EditButton, Show } from '@refinedev/antd';

interface Props {
  resource: string;
  id: string;
}

export function ResourceDetail({ resource, id }: Props) {
  const { queryResult } = useShow({
    resource: resource,
    id,
  });
  const { data, isLoading } = queryResult;
  const { resource: resourceInfo } = useResource();
  const record = data?.data;

  return (
    <AuthorizePage resource={resource} action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resourceInfo?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <Descriptions bordered column={1}>
          <Descriptions.Item label='이름'>{record?.name}</Descriptions.Item>
          <Descriptions.Item label='설명'>
            {record?.description}
          </Descriptions.Item>
          <Descriptions.Item label='생성일'>
            {record?.created_at
              ? new Date(record.created_at).toLocaleString()
              : '-'}
          </Descriptions.Item>
          <Descriptions.Item label='수정일'>
            {record?.updated_at
              ? new Date(record.updated_at).toLocaleString()
              : '-'}
          </Descriptions.Item>
        </Descriptions>
      </Show>
    </AuthorizePage>
  );
}
