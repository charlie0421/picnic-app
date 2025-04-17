'use client';

import { Suspense } from 'react';
import { Authenticated } from '@refinedev/core';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function IndexPage() {
  const router = useRouter();

  useEffect(() => {
    router.push('/dashboard');
  }, [router]);

  return (
    <Suspense>
      <Authenticated key='home-page'>
        <div>리디렉션 중...</div>
      </Authenticated>
    </Suspense>
  );
}
