'use client';

import { Edit, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import { AdminPermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PermissionForm from '@/app/admin_permissions/components/PermissionForm';

export default function PermissionEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<AdminPermission>({
    resource: 'admin_permissions',
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('권한이 성공적으로 수정되었습니다');
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
        <PermissionForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
