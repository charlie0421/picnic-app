import React from 'react';
import PortalGuard from '@/components/PortalGuard';
import { PortalType } from '@/utils/enums';

export default function MyPageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <PortalGuard type={PortalType.MYPAGE}>
      {children}
    </PortalGuard>
  );
} 