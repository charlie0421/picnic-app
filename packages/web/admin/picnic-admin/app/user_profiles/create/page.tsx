'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileCreate } from '../components';

export default function UserProfileCreatePage() {
  return (
    <AuthorizePage action='create'>
      <UserProfileCreate />
    </AuthorizePage>
  );
}
