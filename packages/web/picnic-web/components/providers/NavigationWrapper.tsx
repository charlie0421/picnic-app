'use client';

import { NavigationProvider } from '@/contexts/NavigationContext';
import PortalLayout from '@/components/features/PortalLayout';

export default function NavigationWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <NavigationProvider>
      <PortalLayout>{children}</PortalLayout>
    </NavigationProvider>
  );
} 