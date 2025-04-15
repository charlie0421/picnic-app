'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import VoteList from './components/VoteList';

export default function VoteListPage() {
  return (
    <AuthorizePage action='list'>
      <VoteList />
    </AuthorizePage>
  );
}
