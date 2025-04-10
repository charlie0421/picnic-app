'use client';

import { Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Skeleton, theme } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminRolePermissionsDetail from '@/app/admin_role_permissions/components/AdminRolePermissionsDetail';

export default function RolePermissionShow() {
  const { queryResult } = useShow({
    resource: 'admin_role_permissions',
  });
  const { data, isLoading } = queryResult;
  const { resource } = useResource();
  const { token } = theme.useToken();

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
        title={resource?.meta?.show?.label}
      >
        <AdminRolePermissionsDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
