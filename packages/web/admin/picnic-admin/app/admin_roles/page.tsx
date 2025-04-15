'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import RoleList from './components/RoleList';

export default function RoleListPage() {
  return (
    <AuthorizePage action='list'>
      <RoleList />
    </AuthorizePage>
  );
}
