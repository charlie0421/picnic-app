'use client';

import { useAuth } from '@/contexts/AuthContext';
import { PortalType } from '@/utils/enums';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

interface PortalProps {
  type?: PortalType;
  children: React.ReactNode;
}

// 릴리즈 모드에서 공개될 포탈 목록
const RELEASED_PORTALS = process.env.NEXT_PUBLIC_RELEASED_PORTALS?.split(',') || [];

export default function Portal({ type = PortalType.PUBLIC, children }: PortalProps) {
  const { authState } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // 릴리즈 모드 체크
    if (type !== PortalType.PUBLIC && type !== PortalType.AUTH && type !== PortalType.PROTECTED) {
      if (!RELEASED_PORTALS.includes(type)) {
        router.push('/');
        return;
      }
    }

    if (type === PortalType.AUTH && authState.isAuthenticated) {
      router.push('/');
    } else if (type === PortalType.PROTECTED && !authState.isAuthenticated) {
      router.push('/login');
    }
  }, [type, authState.isAuthenticated, router]);

  return <>{children}</>;
} 