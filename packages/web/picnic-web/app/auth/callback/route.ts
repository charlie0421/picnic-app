import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const code = formData.get('code');
    const state = formData.get('state');

    if (!code || !state) {
      return NextResponse.redirect(new URL('/?error=missing_params', request.url), 302);
    }

    // Supabase 클라이언트 생성
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            return cookieStore.get(name)?.value;
          },
          set(name: string, value: string) {
            cookieStore.set({
              name,
              value,
              path: '/',
              secure: process.env.NODE_ENV === 'production',
              sameSite: 'lax'
            });
          },
          remove(name: string) {
            cookieStore.delete({
              name,
              path: '/'
            });
          },
        },
      }
    );

    // state 값 검증
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('세션 검증 실패:', sessionError);
      return NextResponse.redirect(new URL('/?error=session_error', request.url), 302);
    }

    // Supabase OAuth 콜백 처리
    const { error: oauthError } = await supabase.auth.exchangeCodeForSession(code as string);
    
    if (oauthError) {
      console.error('OAuth 콜백 처리 실패:', oauthError);
      return NextResponse.redirect(new URL('/?error=oauth_error', request.url), 302);
    }

    // 성공 시 메인 페이지로 리다이렉션
    return NextResponse.redirect(new URL('/', request.url), 302);
  } catch (error) {
    console.error('OAuth 콜백 처리 중 오류:', error);
    return NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
  }
} 