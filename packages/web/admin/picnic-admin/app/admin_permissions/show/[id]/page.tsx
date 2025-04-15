'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { useShow, useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminPermissionsDetail from '@/app/admin_permissions/components/AdminPermissionsDetail';
import { AdminPermission } from '@/lib/types/permission';

export default function PermissionShow() {
  const { queryResult } = useShow<AdminPermission>({});
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
        <AdminPermissionsDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
