'use client';

import { Create, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { AdminPermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PermissionForm from '@/app/admin_permissions/components/PermissionForm';

export default function PermissionCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminPermission>({
    resource: 'admin_permissions',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('권한이 성공적으로 생성되었습니다');
    },
  });

  return (
    <AuthorizePage resource='admin_permissions' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <PermissionForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
