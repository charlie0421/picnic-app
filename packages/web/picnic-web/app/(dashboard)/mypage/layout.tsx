import React from 'react';
import Portal from '@/components/Portal';
import { PortalType } from '@/utils/enums';

export default function MyPageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <Portal type={PortalType.PROTECTED}>
      {children}
    </Portal>
  );
} 