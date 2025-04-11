'use client';

import { RewardShow } from '../../components';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useParams } from 'next/navigation';

export default function RewardShowPage() {
  const params = useParams();
  const id = params.id as string;

  return (
    <AuthorizePage resource="reward" action="show">
      <RewardShow id={id} />
    </AuthorizePage>
  );
} 