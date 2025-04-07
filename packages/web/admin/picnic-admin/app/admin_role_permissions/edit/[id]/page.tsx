'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import RolePermissionForm from '@/app/admin_role_permissions/components/RolePermissionForm';
import { AdminRolePermission } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RolePermissionEdit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps } = useForm<AdminRolePermission>({
    resource: 'admin_role_permissions',
    id,
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
  });

  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource='admin_role_permissions' action='edit'>
      <Edit saveButtonProps={saveButtonProps}>
        {contextHolder}
        <RolePermissionForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
