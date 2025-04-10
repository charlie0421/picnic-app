'use client';

import { Edit, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import { AdminUserRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RoleUserForm from '@/app/admin_user_roles/components/RoleUserForm';

export default function RoleUserEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminUserRole>({
    resource: 'admin_user_roles',
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('사용자 역할이 성공적으로 수정되었습니다');
    },
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
  });

  return (
    <AuthorizePage resource='admin_user_roles' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <RoleUserForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
