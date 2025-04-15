'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { Skeleton, theme } from 'antd';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource, useShow } from '@refinedev/core';
import AdminRolesDetail from '@/app/admin_roles/components/AdminRolesDetail';

export default function RoleShow() {
  const { queryResult } = useShow<AdminRole>({
    resource: 'admin_roles',
  });

  const { data, isLoading } = queryResult;
  const { resource } = useResource();
  const { token } = theme.useToken();

  if (isLoading) {
    return (
      <AuthorizePage resource='admin_roles' action='show'>
        <Skeleton active paragraph={{ rows: 5 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='admin_roles' action='show'>
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
