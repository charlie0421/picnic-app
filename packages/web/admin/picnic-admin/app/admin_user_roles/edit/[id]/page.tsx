'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import RoleUserForm from '@/app/admin_user_roles/components/RoleUserForm';
import { AdminUserRole } from '@/lib/types/permission';

export default function RoleUserEdit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps } = useForm<AdminUserRole>({
    resource: 'admin_user_roles',
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
    <Edit saveButtonProps={saveButtonProps}>
      {contextHolder}
      <RoleUserForm
        mode='edit'
        id={id}
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Edit>
  );
}
