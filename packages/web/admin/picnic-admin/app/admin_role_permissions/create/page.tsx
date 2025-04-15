'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RolePermissionForm from '@/app/admin_role_permissions/components/RolePermissionForm';
import { AdminRolePermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function RolePermissionCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminRolePermission>({
    resource: 'admin_role_permissions',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('역할 권한이 성공적으로 생성되었습니다');
    },
  });

  return (
    <AuthorizePage action='create'>
      <Create
        breadcrumb={false}
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
