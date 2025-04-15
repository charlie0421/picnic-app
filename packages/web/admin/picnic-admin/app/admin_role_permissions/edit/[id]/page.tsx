'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import RolePermissionForm from '@/app/admin_role_permissions/components/RolePermissionForm';
import { AdminRolePermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function RolePermissionEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminRolePermission>({
    resource: 'admin_role_permissions',
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('역할 권한이 성공적으로 수정되었습니다');
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
    <AuthorizePage action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
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
