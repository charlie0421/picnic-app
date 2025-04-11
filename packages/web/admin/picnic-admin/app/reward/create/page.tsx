'use client';

import { RewardCreate } from '../components';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RewardCreatePage() {
  return (
    <AuthorizePage resource="reward" action="create">
      <RewardCreate />
    </AuthorizePage>
  );
} 