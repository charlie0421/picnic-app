'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupList from './components/ArtistGroupList';

export default function ArtistGroupListPage() {
  return (
    <AuthorizePage resource='artist_group' action='list'>
      <ArtistGroupList />
    </AuthorizePage>
  );
}
