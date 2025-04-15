'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource, useShow } from '@refinedev/core';
import AdminRolesDetail from '@/app/admin_roles/components/AdminRolesDetail';

export default function RoleShow() {
  const { queryResult } = useShow<AdminRole>({});
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
        <AdminRolesDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
