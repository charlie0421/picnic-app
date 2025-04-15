'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileList } from './components';

export default function UserProfileListPage() {
  return (
    <AuthorizePage action='list'>
      <UserProfileList />
    </AuthorizePage>
  );
}
