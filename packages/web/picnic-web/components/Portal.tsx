'use client';

import { useAuth } from '@/contexts/AuthContext';
import { PortalType } from '@/utils/enums';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect } from 'react';
import { supabase } from '@/utils/supabase-client';

interface PortalProps {
  type?: PortalType;
  children: React.ReactNode;
}

// 릴리즈 모드에서 공개될 포탈 목록
const RELEASED_PORTALS = process.env.NEXT_PUBLIC_RELEASED_PORTALS?.split(',') || [];

export default function Portal({ type = PortalType.PUBLIC, children }: PortalProps) {
  const { authState } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      // 릴리즈 모드 체크
      if (type !== PortalType.PUBLIC && type !== PortalType.AUTH && type !== PortalType.PROTECTED) {
        if (!RELEASED_PORTALS.includes(type)) {
          router.push('/');
          return;
        }
      }

      // 인증 상태에 따른 리다이렉션
      if (type === PortalType.AUTH && session) {
        router.push('/');
      } else if (type === PortalType.PROTECTED && !session) {
        router.push('/login');
      }
    };

    checkAuth();
  }, [type, router, pathname]);

  return <>{children}</>;
} 