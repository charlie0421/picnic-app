'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RolePermissionList from './components/RolePermissionList';

export default function RolePermissionListPage() {
  return (
    <AuthorizePage resource='admin_role_permissions' action='list'>
      <RolePermissionList />
    </AuthorizePage>
  );
}
