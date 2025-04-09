'use client';

import { Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import AdminUserRolesDetail from '@/app/admin_user_roles/components/AdminUserRolesDetail';

export default function UserRoleShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='admin_user_roles' action='show'>
        <Skeleton active paragraph={{ rows: 5 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='admin_user_roles' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
        <AdminUserRolesDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
