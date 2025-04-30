'use client';

import { useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

export default function AuthCallback() {
  const router = useRouter();
  const searchParams = useSearchParams();

  useEffect(() => {
    const error = searchParams.get('error');
    if (error) {
      console.error('OAuth 에러:', error);
      
      // 서버 로그 확인
      fetch('/api/auth/callback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams(window.location.search),
      })
        .then(response => {
          const logs = response.headers.get('x-auth-logs');
          if (logs) {
            console.log('서버 로그:', JSON.parse(logs));
          }
        })
        .catch(console.error);
    }
  }, [searchParams]);

  return null;
} 