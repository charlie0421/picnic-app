'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistList from './components/ArtistList';

export default function ArtistListPage() {
  return (
    <AuthorizePage resource='artist' action='list'>
      <ArtistList />
    </AuthorizePage>
  );
}
