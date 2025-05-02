'use client';

import { useEffect } from 'react';
import { useRouter, useSearchParams, useParams } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import React from 'react';

export default function OAuthCallback() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const paramsPromise = useParams(); // Promise 형태로 제공됨
  const supabase = createBrowserSupabaseClient();

  useEffect(() => {
    const handleOAuthCallback = async () => {
      const params = await paramsPromise; // ✅ 명시적 unwrap
      const provider = params.provider;

      const code = searchParams.get('code');
      const state = searchParams.get('state');

      console.log('--------------------------------');
      console.log('provider', provider);
      console.log('code', code);
      console.log('state', state);
      console.log('--------------------------------');

      if (!code) {
        router.push('/login');
        return;
      }

      const res = await fetch(
        'https://api.picnic.fan/functions/v1/oauth-web-token',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            provider,
            code,
            state,
            redirect_uri: window.location.origin,
          }),
          credentials: 'include',
        },
      );

      const { id_token, access_token, error } = await res.json();

      if (error || (!id_token && !access_token)) {
        console.error('Token Error:', error);
        router.push('/login');
        return;
      }

      const token = id_token || access_token;
      const { error: supabaseError } = await supabase.auth.signInWithIdToken({
        provider: provider as any,
        token,
      });

      if (supabaseError) {
        console.error('Supabase Login Error:', supabaseError);
        router.push('/login');
        return;
      }

      router.push('/');
    };

    handleOAuthCallback();
  }, [paramsPromise, router, searchParams, supabase]);

  return <div>로그인 처리 중...</div>;
}
