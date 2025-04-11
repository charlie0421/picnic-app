'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileList } from './components';

export default function UserProfileListPage() {
  return (
    <AuthorizePage resource="user_profiles" action="list">
      <UserProfileList />
    </AuthorizePage>
  );
} 