'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import BannerList from './components/BannerList';


export default function BannerListPage() {
  return (
    <AuthorizePage action='list'>
      <BannerList />
    </AuthorizePage>
  );
}
