import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    console.log('OAuth 콜백 요청 시작');
    
    const formData = await request.formData();
    const code = formData.get('code');
    const state = formData.get('state');

    console.log('받은 파라미터:', {
      code: code ? '존재함' : '없음',
      state: state ? '존재함' : '없음',
      stateValue: state
    });

    if (!code || !state) {
      console.error('필수 파라미터 누락:', { code, state });
      return NextResponse.redirect(new URL('/?error=missing_params', request.url), 302);
    }

    // state 디코딩
    let stateData;
    try {
      stateData = JSON.parse(atob(state as string));
      console.log('State 데이터:', {
        redirect_url: stateData.redirect_url,
        nonce: stateData.nonce,
        code_verifier: stateData.code_verifier ? '존재함' : '없음'
      });
    } catch (error) {
      console.error('State 디코딩 실패:', error);
      return NextResponse.redirect(new URL('/?error=invalid_state', request.url), 302);
    }

    // Supabase 클라이언트 생성
    console.log('Supabase 클라이언트 생성 시작');
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            const value = cookieStore.get(name)?.value;
            console.log(`쿠키 조회: ${name}`, value ? '존재함' : '없음');
            return value;
          },
          set(name: string, value: string) {
            console.log(`쿠키 설정: ${name}`);
            cookieStore.set({
              name,
              value,
              path: '/',
              secure: process.env.NODE_ENV === 'production',
              sameSite: 'lax'
            });
          },
          remove(name: string) {
            console.log(`쿠키 삭제: ${name}`);
            cookieStore.delete({
              name,
              path: '/'
            });
          },
        },
      }
    );
    console.log('Supabase 클라이언트 생성 완료');

    // state 값 검증
    console.log('세션 검증 시작');
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('세션 검증 실패:', {
        error: sessionError,
        message: sessionError.message,
        status: sessionError.status
      });
      return NextResponse.redirect(new URL('/?error=session_error', request.url), 302);
    }
    console.log('세션 검증 완료:', { session: session ? '존재함' : '없음' });

    // code verifier 확인
    let codeVerifier = cookieStore.get('sb-xtijtefcycoeqludlngc-auth-token-code-verifier')?.value;
    console.log('쿠키에서 Code verifier 상태:', codeVerifier ? '존재함' : '없음');

    // 쿠키에 없으면 state에서 가져오기
    if (!codeVerifier && stateData.code_verifier) {
      codeVerifier = stateData.code_verifier;
      console.log('State에서 Code verifier 가져옴');
    }

    if (!codeVerifier) {
      console.error('Code verifier가 없음');
      return NextResponse.redirect(new URL('/?error=missing_code_verifier', request.url), 302);
    }

    // Supabase OAuth 콜백 처리
    console.log('OAuth 코드 교환 시작');
    const { data: oauthData, error: oauthError } = await supabase.auth.exchangeCodeForSession(code as string);
    
    if (oauthError) {
      console.error('OAuth 콜백 처리 실패:', {
        error: oauthError,
        message: oauthError.message,
        status: oauthError.status,
        details: oauthError
      });
      return NextResponse.redirect(new URL('/?error=oauth_error', request.url), 302);
    }
    console.log('OAuth 코드 교환 완료:', { 
      session: oauthData.session ? '존재함' : '없음',
      user: oauthData.user ? '존재함' : '없음'
    });

    // 성공 시 메인 페이지로 리다이렉션
    console.log('성공적으로 처리 완료, 메인 페이지로 리다이렉션');
    return NextResponse.redirect(new URL('/', request.url), 302);
  } catch (error) {
    console.error('OAuth 콜백 처리 중 예기치 않은 오류:', {
      error,
      message: error instanceof Error ? error.message : '알 수 없는 오류',
      stack: error instanceof Error ? error.stack : undefined
    });
    return NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
  }
} 