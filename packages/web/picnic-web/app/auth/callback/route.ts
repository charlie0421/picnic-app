import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  const logs: string[] = [];
  
  try {
    logs.push('OAuth 콜백 요청 시작');
    
    const formData = await request.formData();
    const code = formData.get('code');
    const state = formData.get('state');

    logs.push(`받은 파라미터: code=${code ? '존재함' : '없음'}, state=${state ? '존재함' : '없음'}`);

    if (!code || !state) {
      logs.push(`필수 파라미터 누락: code=${code}, state=${state}`);
      const response = NextResponse.redirect(new URL('/?error=missing_params', request.url), 302);
      response.headers.set('x-auth-logs', JSON.stringify(logs));
      return response;
    }

    // state에서 code_verifier 추출
    let codeVerifier: string | null = null;
    try {
      const decodedState = Buffer.from(state as string, 'base64').toString('utf-8');
      const stateData = JSON.parse(decodedState);
      codeVerifier = stateData.code_verifier;
      logs.push('state에서 code_verifier 추출 성공');
    } catch (error) {
      logs.push(`state 디코딩 실패: ${error instanceof Error ? error.message : '알 수 없는 오류'}`);
    }

    if (!codeVerifier) {
      logs.push('code_verifier를 찾을 수 없음');
      const response = NextResponse.redirect(new URL('/?error=missing_code_verifier', request.url), 302);
      response.headers.set('x-auth-logs', JSON.stringify(logs));
      return response;
    }

    // Supabase 클라이언트 생성
    logs.push('Supabase 클라이언트 생성 시작');
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            const value = cookieStore.get(name)?.value;
            logs.push(`쿠키 조회: ${name}=${value ? '존재함' : '없음'}`);
            return value;
          },
          set(name: string, value: string) {
            logs.push(`쿠키 설정: ${name}`);
            cookieStore.set({
              name,
              value,
              path: '/',
              secure: process.env.NODE_ENV === 'production',
              sameSite: 'lax'
            });
          },
          remove(name: string) {
            logs.push(`쿠키 삭제: ${name}`);
            cookieStore.delete({
              name,
              path: '/'
            });
          },
        },
      }
    );
    logs.push('Supabase 클라이언트 생성 완료');

    // state 값 검증
    logs.push('세션 검증 시작');
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      logs.push(`세션 검증 실패: ${JSON.stringify({
        message: sessionError.message,
        status: sessionError.status
      })}`);
      const response = NextResponse.redirect(new URL('/?error=session_error', request.url), 302);
      response.headers.set('x-auth-logs', JSON.stringify(logs));
      return response;
    }
    logs.push(`세션 검증 완료: session=${session ? '존재함' : '없음'}`);

    // Supabase OAuth 콜백 처리
    logs.push('OAuth 코드 교환 시작');
    const { data, error: oauthError } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: `${request.nextUrl.origin}/auth/callback`,
        queryParams: {
          code: code as string,
          code_verifier: codeVerifier
        }
      }
    });
    
    if (oauthError) {
      logs.push(`OAuth 콜백 처리 실패: ${JSON.stringify({
        message: oauthError.message,
        status: oauthError.status
      })}`);
      const response = NextResponse.redirect(new URL('/?error=oauth_error', request.url), 302);
      response.headers.set('x-auth-logs', JSON.stringify(logs));
      return response;
    }

    // 성공 시 메인 페이지로 리다이렉션
    logs.push('성공적으로 처리 완료, 메인 페이지로 리다이렉션');
    const response = NextResponse.redirect(new URL('/', request.url), 302);
    response.headers.set('x-auth-logs', JSON.stringify(logs));
    return response;
  } catch (error) {
    logs.push(`예기치 않은 오류: ${error instanceof Error ? error.message : '알 수 없는 오류'}`);
    const response = NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
    response.headers.set('x-auth-logs', JSON.stringify(logs));
    return response;
  }
} 