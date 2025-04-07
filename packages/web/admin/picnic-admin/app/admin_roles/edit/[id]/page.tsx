'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import { RoleForm } from '@/components/permission';
import { AdminRole } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleEdit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps } = useForm<AdminRole>({
    resource: 'admin_roles',
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
    <AuthorizePage resource='admin_roles' action='edit'>
      <Edit saveButtonProps={saveButtonProps}>
        {contextHolder}
        <RoleForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
