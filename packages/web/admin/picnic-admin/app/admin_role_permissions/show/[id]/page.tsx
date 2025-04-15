'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminRolePermissionsDetail from '@/app/admin_role_permissions/components/AdminRolePermissionsDetail';
import { AdminRolePermission } from '@/lib/types/permission';

export default function RolePermissionShow() {
  const { queryResult } = useShow<AdminRolePermission>({});
  const { data, isLoading } = queryResult;
  const { resource } = useResource();
  return (
    <AuthorizePage action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <AdminRolePermissionsDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
