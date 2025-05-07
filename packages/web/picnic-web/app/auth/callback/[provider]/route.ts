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
  const host = request.headers.get('host') || '';
  
  console.log('리디렉션 결정을 위한 정보:', {
    forwardedHost,
    forwardedProto,
    host,
    referer,
    requestUrl: requestUrl.toString(),
    path
  });
  
  // 경로가 슬래시로 시작하지 않으면 추가
  if (!path.startsWith('/')) {
    path = '/' + path;
  }

  // 이미 완전한 URL인 경우
  if (path.startsWith('http://') || path.startsWith('https://')) {
    console.log(`이미 완전한 URL: ${path}`);
    return path;
  }

  // ngrok URL 감지
  if (
    (forwardedHost && forwardedHost.includes('ngrok')) || 
    (host && host.includes('ngrok'))
  ) {
    console.log(`ngrok URL 감지됨: ${forwardedHost || host}`);
    const protocol = forwardedProto || 'https';
    return `${protocol}://${forwardedHost || host}${path}`;
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
  const redirectUrl = new URL(path, requestUrl.origin).toString();
  console.log(`최종 리디렉션 URL: ${redirectUrl}`);
  return redirectUrl;
}

// Next.js App Router 라우트 핸들러
export async function GET(request: NextRequest, { params }: { params: { provider: string } }) {
  // context.params에서 provider 값 추출
  const { provider } = params;  // 타입 안전하게 수정
  
  try {
    // 현재 제공자 정보 가져오기
    console.log(`Processing callback for provider: ${provider}`);
    
    // 요청 헤더 로깅 (디버깅용)
    console.log('요청 헤더:');
    const headerEntries = Array.from(request.headers.entries());
    for (const [key, value] of headerEntries) {
      console.log(`${key}: ${value}`);
    }
    
    const host = request.headers.get('host') || '';
    const referer = request.headers.get('referer') || '';
    
    // URL에서 현재 코드와 상태 값을 추출
    const requestUrl = new URL(request.url);
    const code = requestUrl.searchParams.get('code');
    const state = requestUrl.searchParams.get('state');
    
    console.log(`Auth callback details:`, {
      provider,
      hasCode: !!code,
      hasState: !!state,
      url: requestUrl.toString(),
      host,
      referer
    });
    
    // Origin 확인
    const originUrl = requestUrl.origin;
    // 환경 변수 확인
    const configuredRedirectUri = process.env.NEXT_PUBLIC_GOOGLE_REDIRECT_URI || `${originUrl}/auth/callback/google`;
    
    console.log('설정된 리디렉션 정보:', {
      originUrl,
      configuredRedirectUri,
      webDomain: process.env.NEXT_PUBLIC_WEB_DOMAIN
    });
    
    // 오류 파라미터가 있는지 확인
    const error = requestUrl.searchParams.get('error');
    const errorDescription = requestUrl.searchParams.get('error_description');
    
    if (error) {
      console.error(`Auth callback error from ${provider}:`, {
        error,
        errorDescription
      });
      
      // 루트 페이지로 리디렉션하며 오류 파라미터 추가
      return NextResponse.redirect(
        getSafeRedirectUrl(request, `/?error=true&error_type=${error}&error_description=${errorDescription || '알 수 없는 오류'}&provider=${provider}`)
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
      getSafeRedirectUrl(request, `/login?auth_error=true&error_type=missing_code&provider=${provider}`)
    );
  } catch (error: any) {
    console.error('Global auth callback error:', error);
    
    // 전체 오류 시 로그인 페이지로 리디렉션
    return NextResponse.redirect(
      getSafeRedirectUrl(request, `/login?auth_error=true&error_description=${error.message || '알 수 없는 오류'}`)
    );
  }
}

// 구글 콜백 처리 함수
async function handleGoogleCallback(request: NextRequest, code: string, state: string | null) {
  try {
    console.log('구글 콜백 처리 시작');
    console.log('코드 확인:', code.substring(0, 10) + '...');
    console.log('state 값:', state);
    
    // Supabase를 사용하여 코드를 세션으로 교환
    console.log('구글 코드를 세션으로 교환 중...');
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    
    if (error) {
      console.error('세션 교환 오류:', error);
      return NextResponse.redirect(
        getSafeRedirectUrl(request, `/?auth_error=true&error_type=session_exchange&error_description=${error.message}&provider=google`)
      );
    }
    
    // 세션 정보 확인
    console.log('세션 교환 성공:', {
      hasSession: !!data.session,
      hasUser: !!data.session?.user,
      userId: data.session?.user?.id,
    });
    
    // state에서 정보 추출
    let originalUrl = '';
    let isNgrok = false;
    let hostInfo = '';
    
    if (state) {
      try {
        const stateData = JSON.parse(state);
        console.log('파싱된 state 데이터:', stateData);
        
        // redirectUrl 정보 추출
        if (stateData.redirectUrl) {
          originalUrl = stateData.redirectUrl;
          console.log(`state에서 redirectUrl 추출: ${originalUrl}`);
        } else if (stateData.originalUrl) {
          originalUrl = stateData.originalUrl;
          console.log(`state에서 originalUrl 추출: ${originalUrl}`);
        }
        
        // ngrok 정보 추출
        if (stateData.isNgrok !== undefined) {
          isNgrok = stateData.isNgrok;
          console.log(`state에서 isNgrok 추출: ${isNgrok}`);
        }
        
        // 호스트 정보 추출
        if (stateData.host) {
          hostInfo = stateData.host;
          console.log(`state에서 host 추출: ${hostInfo}`);
        }
      } catch (e) {
        console.error('state 파싱 오류:', e);
      }
    }
    
    // 요청 헤더 확인
    const forwardedHost = request.headers.get('x-forwarded-host');
    const forwardedProto = request.headers.get('x-forwarded-proto');
    const host = request.headers.get('host') || '';
    
    console.log('요청 헤더 정보:', {
      forwardedHost,
      forwardedProto,
      host,
      'user-agent': request.headers.get('user-agent')
    });
    
    // ngrok 환경 재확인
    if (!isNgrok) {
      isNgrok = !!((forwardedHost && forwardedHost.includes('ngrok')) || 
                   (host && host.includes('ngrok')));
      console.log(`헤더 기반 ngrok 감지: ${isNgrok}`);
    }
    
    // 리디렉션 URI - 현재 요청 URL 기반
    const requestUrl = new URL(request.url);
    
    // 목적지 URL 결정
    let targetUrl = '';
    
    if (originalUrl) {
      targetUrl = originalUrl;
    } else if (isNgrok && forwardedHost) {
      const protocol = forwardedProto || 'https';
      targetUrl = `${protocol}://${forwardedHost}`;
    } else {
      targetUrl = requestUrl.origin;
    }
    
    // 최종 URL에 원래 경로가 있는지 확인하고 없으면 루트로 설정
    if (targetUrl.endsWith('/auth/callback/google')) {
      targetUrl = targetUrl.replace('/auth/callback/google', '');
    }
    
    console.log('최종 타겟 URL:', targetUrl);
    
    // 직접 HTML 응답으로 리디렉션
    if (originalUrl && originalUrl !== requestUrl.origin && !originalUrl.includes('picnic.fan')) {
      console.log(`원래 도메인으로 리디렉션: ${originalUrl}`);
      
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
          localStorage.setItem('auth_provider', 'google');
          
          // 원래 도메인으로 리디렉션
          console.log('로그인 성공, 원래 도메인으로 리디렉션: ${originalUrl}');
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
    console.log(`일반 리디렉션 처리, 목적지: ${targetUrl}`);
    const response = NextResponse.redirect(getSafeRedirectUrl(request, targetUrl));
    
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
    // 최종 오류 시 홈으로 리디렉션
    return NextResponse.redirect(getSafeRedirectUrl(request, '/'));
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
        getSafeRedirectUrl(request, `/?auth_error=true&error_type=session_exchange&error_description=${error.message}&provider=${provider}`)
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
      getSafeRedirectUrl(request, `/?auth_error=true&error_type=${provider}_callback&error_description=${error.message || '알 수 없는 오류'}`)
    );
  }
} 