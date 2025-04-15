'use client';

import React from 'react';
import { Show, EditButton, DeleteButton } from '@refinedev/antd';
import { useShow, useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ShowPage() {
  const { queryResult } = useShow({
    resource: '${dirname}',
  });
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  return (
    <AuthorizePage resource='${dirname}' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
        title={resource?.meta?.show?.label}
      >
        {/* 상세 컴포넌트 내용 */}
      </Show>
    </AuthorizePage>
  );
}
