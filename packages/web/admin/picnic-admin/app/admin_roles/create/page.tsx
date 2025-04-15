'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RoleForm from '@/app/admin_roles/components/RoleForm';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function RoleCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminRole>({
    resource: 'admin_roles',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('역할이 성공적으로 생성되었습니다');
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
        <RoleForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
