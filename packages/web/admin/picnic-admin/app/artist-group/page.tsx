'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupList from './components/ArtistGroupList';

export default function ArtistGroupListPage() {
  return (
    <AuthorizePage action='list'>
      <ArtistGroupList />
    </AuthorizePage>
  );
}
