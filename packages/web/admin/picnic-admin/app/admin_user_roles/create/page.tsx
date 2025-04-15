'use client';

import { Create, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { AdminUserRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RoleUserForm from '@/app/admin_user_roles/components/RoleUserForm';

export default function RoleUserCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminUserRole>({
    resource: 'admin_user_roles',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('사용자 역할이 성공적으로 생성되었습니다');
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
        <RoleUserForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
