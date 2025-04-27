'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/utils/supabase-client';

export default function AuthCallback() {
  const router = useRouter();

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('인증 에러:', error);
          router.push('/login');
          return;
        }

        if (session) {
          router.push('/');
        } else {
          router.push('/login');
        }
      } catch (error) {
        console.error('콜백 처리 중 에러:', error);
        router.push('/login');
      }
    };

    handleCallback();
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <h1 className="text-2xl font-bold mb-4">인증 처리 중...</h1>
        <p>잠시만 기다려주세요.</p>
      </div>
    </div>
  );
} 