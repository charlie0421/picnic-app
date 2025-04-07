'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RoleForm from '@/app/admin_roles/components/RoleForm';
import { AdminRole } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleCreate() {
  const { formProps, saveButtonProps } = useForm<AdminRole>({
    resource: 'admin_roles',
  });
  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource='admin_roles' action='create'>
      <Create saveButtonProps={saveButtonProps}>
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
