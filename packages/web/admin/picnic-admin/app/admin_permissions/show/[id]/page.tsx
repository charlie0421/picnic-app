'use client';

import { Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminPermissionsDetail from '@/app/admin_permissions/components/AdminPermissionsDetail';

export default function PermissionShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='admin_permissions' action='show'>
        <Skeleton active paragraph={{ rows: 5 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='admin_permissions' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
        <AdminPermissionsDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
