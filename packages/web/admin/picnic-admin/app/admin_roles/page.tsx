'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RoleList from './components/RoleList';

export default function RoleListPage() {
  return (
    <AuthorizePage resource='admin_roles' action='list'>
      <RoleList />
    </AuthorizePage>
  );
}
