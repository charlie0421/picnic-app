'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RolePermissionForm from '@/app/admin_role_permissions/components/RolePermissionForm';
import { AdminRolePermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function RolePermissionCreate() {
  const { formProps, saveButtonProps } = useForm<AdminRolePermission>({
    resource: 'admin_role_permissions',
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  return (
    <AuthorizePage resource='admin_role_permissions' action='create'>
      <Create
        breadcrumb={false}
        goBack={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <RolePermissionForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
