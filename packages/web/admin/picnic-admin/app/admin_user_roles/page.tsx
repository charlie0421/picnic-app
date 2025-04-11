'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RoleUserList from './components/RoleUserList';

export default function RoleUserListPage() {
  return (
    <AuthorizePage resource='admin_user_roles' action='list'>
      <RoleUserList />
    </AuthorizePage>
  );
}
