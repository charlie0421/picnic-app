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

export default function PortalGuard({ type = PortalType.PUBLIC, children }: PortalProps) {
  const { authState } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      // 인증 상태에 따른 리다이렉션
      if (type === PortalType.AUTH && session) {
        router.push('/');
      } else if (type === PortalType.AUTH && !session) {
        router.push('/login');
      }
    };

    checkAuth();
  }, [type, router, pathname]);

  return <>{children}</>;
} 