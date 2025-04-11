'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import BannerList from './components/BannerList';

export default function BannerListPage() {
  return (
    <AuthorizePage resource='banner' action='list'>
      <BannerList />
    </AuthorizePage>
  );
}
