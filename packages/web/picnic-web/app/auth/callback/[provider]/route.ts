import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Supabase 클라이언트 생성
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// 안전한 리디렉션 URL 가져오기 (ngrok 지원)
function getSafeRedirectUrl(request: NextRequest, path: string = '/'): string {
  // 요청 헤더에서 정보 추출
  const forwardedHost = request.headers.get('x-forwarded-host');
  const forwardedProto = request.headers.get('x-forwarded-proto');
  const requestUrl = new URL(request.url);
  const referer = request.headers.get('referer') || '';
  
  console.log('리디렉션 결정을 위한 정보:', {
    forwardedHost,
    forwardedProto,
    referer,
    requestUrl: requestUrl.toString()
  });
  
  // 경로가 슬래시로 시작하지 않으면 추가
  if (!path.startsWith('/')) {
    path = '/' + path;
  }

  // ngrok URL 감지
  if (forwardedHost && forwardedHost.includes('ngrok')) {
    console.log(`ngrok URL 감지됨: ${forwardedHost}`);
    const protocol = forwardedProto || 'https';
    return `${protocol}://${forwardedHost}${path}`;
  }
  
  // 리퍼러에서 호스트 추출 시도
  if (referer && !referer.includes('picnic.fan')) {
    try {
      const refererUrl = new URL(referer);
      console.log(`리퍼러에서 호스트 추출: ${refererUrl.origin}`);
      return new URL(path, refererUrl.origin).toString();
    } catch (e) {
      console.error('리퍼러 URL 파싱 오류:', e);
    }
  }
  
  // 일반적인 경우는 요청의 origin 사용
  return new URL(path, requestUrl.origin).toString();
}

// Next.js App Router 라우트 핸들러
export async function GET(request: NextRequest, context: any) {
  // context.params에서 provider 값 추출
  const provider = context.params?.provider;
  
  try {
    // 현재 제공자 정보 가져오기
    console.log(`Processing callback for provider: ${provider}`);
    
    // 요청 헤더 로깅 (디버깅용)
    console.log('요청 헤더:');
    const headerEntries = Array.from(request.headers.entries());
    for (const [key, value] of headerEntries) {
      console.log(`${key}: ${value}`);
    }
    
    // URL에서 현재 코드와 상태 값을 추출
    const requestUrl = new URL(request.url);
    const code = requestUrl.searchParams.get('code');
    const state = requestUrl.searchParams.get('state');
    
    console.log(`Auth callback details:`, {
      provider,
      hasCode: !!code,
      hasState: !!state,
      url: requestUrl.toString()
    });
    
    // 오류 파라미터가 있는지 확인
    const error = requestUrl.searchParams.get('error');
    const errorDescription = requestUrl.searchParams.get('error_description');
    
    if (error) {
      console.error(`Auth callback error from ${provider}:`, {
        error,
        errorDescription
      });
      
      // 로그인 페이지로 다시 리디렉션하며 오류 파라미터 추가
      return NextResponse.redirect(
        getSafeRedirectUrl(request, `/login?error=${error}&error_description=${errorDescription || '알 수 없는 오류'}&provider=${provider}`)
      );
    }
    
    // 코드가 있으면 세션으로 교환
    if (code) {
      // 제공자별 처리 (구글의 경우 특별 처리)
      if (provider === 'google') {
        return await handleGoogleCallback(request, code, state);
      }
      
      // 다른 제공자의 경우 기본 처리
      return await handleDefaultCallback(request, code, state, provider);
    }
    
    // 코드가 없으면 잘못된 요청으로 처리
    console.error(`Missing code parameter in ${provider} callback`);
    return NextResponse.redirect(
      getSafeRedirectUrl(request, `/login?error=missing_code&provider=${provider}`)
    );
  } catch (error: any) {
    console.error('Global auth callback error:', error);
    
    // 전체 오류 시 로그인 페이지로 리디렉션
    return NextResponse.redirect(
      getSafeRedirectUrl(request, `/login?error=callback_error&error_description=${error.message || '알 수 없는 오류'}`)
    );
  }
}

// 구글 콜백 처리 함수
async function handleGoogleCallback(request: NextRequest, code: string, state: string | null) {
  try {
    console.log('구글 콜백 처리 시작');
    
    // state에서 원래 URL 추출
    let originalUrl = '';
    if (state) {
      try {
        const stateData = JSON.parse(state);
        if (stateData.originalUrl) {
          originalUrl = stateData.originalUrl;
          console.log(`state에서 원래 URL 추출: ${originalUrl}`);
        }
      } catch (e) {
        console.error('state 파싱 오류:', e);
      }
    }
    
    // 리디렉션 URI - 현재 요청 URL 기반
    const requestUrl = new URL(request.url);
    const redirectUri = `${requestUrl.origin}/auth/callback/google`;
    
    // Supabase를 사용하여 코드를 세션으로 교환
    console.log(`Exchanging code for session with Supabase...`);
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    
    if (error) {
      console.error(`Session exchange error for google:`, error);
      return NextResponse.redirect(
        getSafeRedirectUrl(request, `/login?error=session_exchange&error_description=${error.message}&provider=google`)
      );
    }
    
    // 세션 정보 확인
    console.log(`Google auth successful:`, {
      hasSession: !!data.session,
      hasUser: !!data.session?.user,
      userId: data.session?.user?.id,
    });
    
    // 원래 URL이 있고 현재 호스트와 다른 경우 (예: ngrok)
    if (originalUrl && originalUrl !== requestUrl.origin && !originalUrl.includes('picnic.fan')) {
      console.log(`원래 URL로 리디렉션: ${originalUrl}`);
      
      // 인증 성공 후 원래 URL로 리디렉션하는 HTML 응답
      const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>로그인 성공</title>
        <script>
          // 로그인 성공 표시
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', 'google');
          
          // 인증 이벤트 발생
          try {
            window.dispatchEvent(new Event('auth.state.changed'));
            window.dispatchEvent(new Event('supabase.auth.session-update'));
          } catch (e) {
            console.error('이벤트 발생 오류:', e);
          }
          
          // 원래 URL로 리디렉션
          console.log('로그인 성공, 원래 URL로 리디렉션: ${originalUrl}');
          window.location.href = '${originalUrl}';
        </script>
      </head>
      <body>
        <h1>로그인 성공</h1>
        <p>잠시 후 원래 페이지로 이동합니다...</p>
      </body>
      </html>
      `;
      
      return new Response(html, {
        status: 200,
        headers: {
          'Content-Type': 'text/html',
        },
      });
    }
    
    // 일반적인 리디렉션 처리
    console.log(`일반 리디렉션 처리, 목적지: /`);
    const response = NextResponse.redirect(getSafeRedirectUrl(request, '/'));
    
    // 인증 성공 플래그 설정 (디버깅용)
    response.cookies.set('auth_success', 'true', { 
      maxAge: 60,
      path: '/',
      httpOnly: false,
      sameSite: 'lax'
    });
    response.cookies.set('auth_provider', 'google', {
      maxAge: 60,
      path: '/',
      httpOnly: false,
      sameSite: 'lax'
    });
    
    return response;
  } catch (error: any) {
    console.error('구글 콜백 처리 중 오류:', error);
    return NextResponse.redirect(
      getSafeRedirectUrl(request, `/login?error=google_callback&error_description=${error.message || '알 수 없는 오류'}`)
    );
  }
}

// 기본 콜백 처리 함수 (다른 제공자용)
async function handleDefaultCallback(request: NextRequest, code: string, state: string | null, provider: string) {
  try {
    // 홈페이지 URL 결정
    let homeUrl = '/';
    
    // state에 원래 URL 정보가 포함되어 있을 수 있음
    let originalDomain = '';
    if (state) {
      try {
        // state가 JSON 문자열인지 확인
        const stateData = JSON.parse(state);
        if (stateData.redirectUrl) {
          originalDomain = stateData.redirectUrl;
          console.log(`state에서 원래 도메인 추출: ${originalDomain}`);
          // 원래 도메인으로 홈 URL 설정
          if (originalDomain) {
            homeUrl = originalDomain;
          }
        }
      } catch (e) {
        // JSON이 아닌 경우 무시
        console.log('state는 JSON이 아닙니다:', state);
      }
    }
    
    // Supabase를 사용하여 코드를 세션으로 교환
    console.log(`Exchanging code for session...`);
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    
    if (error) {
      console.error(`Session exchange error for ${provider}:`, error);
      return NextResponse.redirect(
        getSafeRedirectUrl(request, `/login?error=session_exchange&error_description=${error.message}&provider=${provider}`)
      );
    }
    
    // 세션 정보 확인
    console.log(`Session exchange successful:`, {
      hasSession: !!data.session,
      hasUser: !!data.session?.user,
      userId: data.session?.user?.id,
    });
    
    // 직접 HTML 응답으로 리디렉션
    const requestUrl = new URL(request.url);
    if (originalDomain && originalDomain !== requestUrl.origin && !originalDomain.includes('picnic.fan')) {
      console.log(`원래 도메인으로 리디렉션: ${originalDomain}`);
      
      // 인증 성공 후 원래 도메인으로 리디렉션하는 HTML 응답
      const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>로그인 성공</title>
        <script>
          // 로그인 성공 표시
          localStorage.setItem('auth_success', 'true');
          localStorage.setItem('auth_provider', '${provider}');
          
          // 인증 이벤트 발생
          window.dispatchEvent(new Event('auth.state.changed'));
          
          // 원래 도메인으로 리디렉션
          console.log('로그인 성공, 원래 도메인으로 리디렉션: ${originalDomain}');
          window.location.href = '${originalDomain}';
        </script>
      </head>
      <body>
        <h1>로그인 성공</h1>
        <p>잠시 후 원래 페이지로 이동합니다...</p>
      </body>
      </html>
      `;
      
      return new Response(html, {
        status: 200,
        headers: {
          'Content-Type': 'text/html',
        },
      });
    }
    
    // 일반적인 리디렉션 처리
    console.log(`일반 리디렉션 처리, 목적지: ${homeUrl}`);
    const response = NextResponse.redirect(getSafeRedirectUrl(request, homeUrl));
    
    // 인증 성공 플래그 설정 (디버깅용)
    response.cookies.set('auth_success', 'true', { 
      maxAge: 60,
      path: '/',
      httpOnly: false,
      sameSite: 'lax'
    });
    response.cookies.set('auth_provider', provider, {
      maxAge: 60,
      path: '/',
      httpOnly: false,
      sameSite: 'lax'
    });
    
    return response;
  } catch (error: any) {
    console.error(`${provider} 콜백 처리 중 오류:`, error);
    return NextResponse.redirect(
      getSafeRedirectUrl(request, `/login?error=${provider}_callback&error_description=${error.message || '알 수 없는 오류'}`)
    );
  }
} 