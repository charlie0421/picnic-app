'use client';

import { RewardList } from './components';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RewardPage() {
  return (
    <AuthorizePage action='list'>
      <RewardList />
    </AuthorizePage>
  );
}
