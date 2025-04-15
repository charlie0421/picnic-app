'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RolePermissionList from './components/RolePermissionList';

export default function RolePermissionListPage() {
  return (
    <AuthorizePage action='list'>
      <RolePermissionList />
    </AuthorizePage>
  );
}
