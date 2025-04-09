'use client';

import { Show } from '@refinedev/antd';
import { Skeleton } from 'antd';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource, useShow } from '@refinedev/core';
import AdminRolesDetail from '@/app/admin_roles/components/AdminRolesDetail';

export default function RoleShow(params: { params: { id: string } }) {
  const { queryResult } = useShow<AdminRole>({
    resource: 'admin_roles',
    id: params.params.id,
  });

  const { data, isLoading } = queryResult;
  const { resource } = useResource();

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
        
        title={resource?.meta?.label}
      >
        <AdminRolesDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
