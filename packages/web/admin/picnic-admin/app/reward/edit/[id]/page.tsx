'use client';

import { RewardEdit } from '../../components';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useParams } from 'next/navigation';

export default function RewardEditPage() {
  const params = useParams();
  const id = params.id as string;

  return (
    <AuthorizePage resource="reward" action="edit">
      <RewardEdit id={id} />
    </AuthorizePage>
  );
} 