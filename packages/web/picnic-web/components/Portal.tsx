'use client';

import { useAuth } from '@/contexts/AuthContext';
import { PortalType } from '@/utils/enums';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

interface PortalProps {
  type?: PortalType;
  children: React.ReactNode;
}

export default function Portal({ type = PortalType.PUBLIC, children }: PortalProps) {
  const { authState } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (type === PortalType.AUTH && authState.isAuthenticated) {
      router.push('/');
    } else if (type === PortalType.PROTECTED && !authState.isAuthenticated) {
      router.push('/login');
    }
  }, [type, authState.isAuthenticated, router]);

  return <>{children}</>;
} 