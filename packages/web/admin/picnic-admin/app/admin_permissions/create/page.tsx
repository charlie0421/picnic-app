'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import PermissionForm from '@/app/admin_permissions/components/PermissionForm';
import { AdminPermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function PermissionCreate() {
  const { formProps, saveButtonProps } = useForm<AdminPermission>({
    resource: 'admin_permissions',
  });
  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource='admin_permissions' action='create'>
      <Create saveButtonProps={saveButtonProps}>
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
