'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import MediaList from './components/MediaList';

export default function MediaListPage() {
  return (
    <AuthorizePage resource='media' action='list'>
      <MediaList />
    </AuthorizePage>
  );
}
