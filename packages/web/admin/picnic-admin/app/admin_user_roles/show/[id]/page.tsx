'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminUserRolesDetail from '@/app/admin_user_roles/components/AdminUserRolesDetail';
import { AdminUserRole } from '@/lib/types/permission';

export default function UserRoleShow() {
  const { queryResult } = useShow<AdminUserRole>({});
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
        <AdminUserRolesDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
