'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RoleForm from '@/app/admin_roles/components/RoleForm';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function RoleCreate() {
  const { formProps, saveButtonProps } = useForm<AdminRole>({
    resource: 'admin_roles',
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  return (
    <AuthorizePage resource='admin_roles' action='create'>
      <Create
        breadcrumb={false}
        goBack={false}
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
