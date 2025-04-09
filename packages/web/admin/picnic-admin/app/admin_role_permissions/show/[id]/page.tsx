'use client';

import { Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminRolePermissionsDetail from '@/app/admin_role_permissions/components/AdminRolePermissionsDetail';

export default function RolePermissionShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='admin_role_permissions' action='show'>
        <Skeleton active paragraph={{ rows: 5 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='admin_role_permissions' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
        <AdminRolePermissionsDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
