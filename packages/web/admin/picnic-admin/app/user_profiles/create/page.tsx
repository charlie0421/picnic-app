'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileCreate } from '../components';

export default function UserProfileCreatePage() {
  return (
    <AuthorizePage resource="user_profiles" action="create">
      <UserProfileCreate />
    </AuthorizePage>
  );
} 