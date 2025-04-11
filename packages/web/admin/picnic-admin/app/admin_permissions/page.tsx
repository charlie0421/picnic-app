'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PermissionList from './components/PermissionList';

export default function PermissionListPage() {
  return (
    <AuthorizePage resource='admin_permissions' action='list'>
      <PermissionList />
    </AuthorizePage>
  );
}
