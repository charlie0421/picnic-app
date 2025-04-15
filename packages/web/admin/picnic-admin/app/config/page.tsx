'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ConfigList from './components/ConfigList';

export default function ConfigListPage() {
  return (
    <AuthorizePage action='list'>
      <ConfigList />
    </AuthorizePage>
  );
}
