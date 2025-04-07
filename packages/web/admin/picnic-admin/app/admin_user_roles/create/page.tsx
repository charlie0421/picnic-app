'use client';

import { Create, useForm } from '@refinedev/antd';
// import { useCan } from '@refinedev/core'; // 제거
import { message /* Spin, Result 제거 */ } from 'antd';
import RoleUserForm from '@/app/admin_user_roles/components/RoleUserForm';
import { AdminUserRole } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage'; // 임포트

export default function RoleUserCreate() {
  // 권한 확인 로직 제거
  // const { data: canAccessData, isLoading: isLoadingAccess } = useCan({
  //   resource: 'admin_user_roles',
  //   action: 'create',
  // });

  const { formProps, saveButtonProps } = useForm<AdminUserRole>({
    resource: 'admin_user_roles',
  });
  const [messageApi, contextHolder] = message.useMessage();

  // 로딩 및 권한 확인 로직 제거
  // if (isLoadingAccess) { ... }
  // if (!canAccessData?.can) { ... }

  // AuthorizePage 로 감싸기
  return (
    <AuthorizePage resource='admin_user_roles' action='create'>
      <Create saveButtonProps={saveButtonProps}>
        {contextHolder}
        <RoleUserForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
