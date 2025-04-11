'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileShow } from '../../components';
import { useParams } from 'next/navigation';

export default function UserProfileShowPage() {
  const params = useParams();
  const id = params.id as string;

  return (
    <AuthorizePage resource="user_profiles" action="show">
      <UserProfileShow id={id} />
    </AuthorizePage>
  );
} 