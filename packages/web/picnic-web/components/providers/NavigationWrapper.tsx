'use client';

import { NavigationProvider } from '@/contexts/NavigationContext';
import Portal from '@/components/features/Portal';

export default function NavigationWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <NavigationProvider>
      <Portal>{children}</Portal>
    </NavigationProvider>
  );
} 