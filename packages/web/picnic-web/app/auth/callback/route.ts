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
            try {
              cookieStore.set(name, value, options);
            } catch (error) {
              // ReadonlyRequestCookies에서는 쿠키를 설정할 수 없음
            }
          },
          remove(name: string, options: any) {
            try {
              cookieStore.delete(name, options);
            } catch (error) {
              // ReadonlyRequestCookies에서는 쿠키를 삭제할 수 없음
            }
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
    
    const response = NextResponse.redirect(new URL(redirectUrl), 302);

    // 쿠키 복사
    const supabaseCookie = cookieStore.get('sb-access-token');
    if (supabaseCookie) {
      response.cookies.set('sb-access-token', supabaseCookie.value, supabaseCookie);
    }

    // 응답 헤더에 state 추가
    response.headers.set('x-supabase-state', state as string);

    return response;
  } catch (error) {
    console.error('OAuth 콜백 처리 중 오류:', error);
    return NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
  }
} 