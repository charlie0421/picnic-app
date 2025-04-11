'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileEdit } from '../../components';
import { useParams } from 'next/navigation';

export default function UserProfileEditPage() {
  const params = useParams();
  const id = params.id as string;

  return (
    <AuthorizePage resource="user_profiles" action="edit">
      <UserProfileEdit id={id} />
    </AuthorizePage>
  );
} 