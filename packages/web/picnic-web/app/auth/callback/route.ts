import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const code = formData.get('code');
    const state = formData.get('state');

    // Supabase 클라이언트 생성
    const cookieStore = cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            return cookieStore.get(name)?.value;
          },
          set(name: string, value: string, options: any) {
            cookieStore.set({ name, value, ...options });
          },
          remove(name: string, options: any) {
            cookieStore.delete({ name, ...options });
          },
        },
      }
    );

    // 현재 state 값 검증
    const { data: { session }, error } = await supabase.auth.verifyOAuthState({ state: state as string });
    
    if (error) {
      console.error('OAuth state 검증 실패:', error);
      return NextResponse.redirect(new URL('/?error=invalid_state', request.url), 302);
    }

    // Supabase 콜백 URL로 리다이렉션
    const redirectUrl = `https://xtijtefcycoeqludlngc.supabase.co/auth/v1/callback?code=${encodeURIComponent(code as string)}&state=${encodeURIComponent(state as string)}`;
    
    return NextResponse.redirect(new URL(redirectUrl), 302);
  } catch (error) {
    console.error('OAuth 콜백 처리 중 오류:', error);
    return NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
  }
} 