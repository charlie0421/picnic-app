import { useState, useCallback, useRef } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase-client';
import { SocialProvider } from '../types/auth';
import { debugLog } from '../utils/debugUtils';
import { 
  generateCodeVerifier, 
  generateCodeChallenge, 
  storeCodeVerifier,
  getStoredCodeVerifier,
  clearCodeVerifier
} from '../utils/pkceUtils';

// 인증 처리 관련 훅
export const useAuthHandlers = () => {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  
  // 재호출 방지를 위한 참조 객체
  const processingRef = useRef(false);

  // 인증 성공 후 처리를 위한 함수
  const handleAuthSuccess = useCallback((data: any, provider: string = 'apple') => {
    const session = data.session;
    if (!session) {
      console.error('세션 정보가 없습니다');
      setError('인증은 성공했으나 세션 정보가 없습니다.');
      return false;
    }

    // 로딩 상태로 UI 변경 - 로그인 폼 숨김
    setLoading(true);

    // 세션 정보 저장
    try {
      localStorage.setItem('auth_session_active', 'true');
      localStorage.setItem('auth_provider', provider);
    } catch (e) {
      // 무시: 저장 실패해도 인증 과정에는 영향 없음
    }
    
    // 직접 홈으로 이동 (라우터 사용하지 않음)
    console.log('로그인 성공, 홈으로 이동합니다.');
    window.location.href = '/';
    
    return true;
  }, []);

  // ngrok URL을 감지하여 올바른 리디렉션 URL 생성
  const getRedirectUrl = useCallback((provider: string) => {
    // ngrok 환경 감지 (브라우저에서만 작동)
    const isNgrok = typeof window !== 'undefined' && 
      (window.location.hostname.includes('ngrok') || 
       window.location.host.includes('ngrok'));
    
    // 현재 호스트 감지
    const currentHost = typeof window !== 'undefined' ? window.location.host : '';
    const protocol = typeof window !== 'undefined' && window.location.protocol === 'https:' ? 'https' : 'http';
    
    console.log('현재 환경:', {
      isNgrok,
      host: currentHost,
      protocol
    });
    
    // 콜백 URL 생성
    const redirectUrl = `${protocol}://${currentHost}/auth/callback/${provider}`;
    console.log(`리디렉션 URL: ${redirectUrl}`);
    
    return redirectUrl;
  }, []);

  // 인증 상태 확인
  const checkAuth = useCallback(async () => {
    try {
      const { data } = await supabase.auth.getSession();
      
      // 이미 로그인된 경우 즉시 홈으로 리디렉션
      if (data.session) {
        console.log('이미 로그인 상태, 홈으로 리디렉션합니다.');
        window.location.href = '/';
        return;
      }
      
      // 로그인이 필요한 경우에만 로딩 상태 해제
      setLoading(false);
    } catch (e) {
      // 세션 확인 실패 - 로그인 화면 표시
      console.error('세션 확인 실패:', e);
      setLoading(false);
    }
  }, [supabase]);

  // 인증 코드 확인 및 세션 처리 함수
  const checkForAuthCode = useCallback(async () => {
    // 이미 처리 중이면 중복 실행 방지
    if (processingRef.current) {
      console.log('이미 인증 코드 확인 중입니다.');
      return;
    }
    
    // 처리 시작 플래그 설정
    processingRef.current = true;
    
    try {
      // 로딩 상태 표시
      setLoading(true);
      
      if (typeof window !== 'undefined') {
        // 현재 URL 및 경로 정보 기록
        debugLog('현재 URL 및 경로 정보', {
          href: window.location.href,
          pathname: window.location.pathname,
          search: window.location.search,
          hash: window.location.hash
        });
        
        // NgRok 환경 확인
        const isNgrok = 
          window.location.hostname.includes('ngrok') || 
          window.location.host.includes('ngrok') ||
          /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(window.location.hostname);
        
        if (isNgrok) {
          debugLog('NgRok 환경에서 인증 코드 확인', { 
            url: window.location.href,
            pathname: window.location.pathname
          });
        }
        
        // 콜백 경로 체크 - 더 유연하게 변경
        const isCallbackPath = (
          window.location.pathname.includes('/auth/callback/') || 
          window.location.pathname.includes('/en/auth/callback/')
        );
        
        if (isCallbackPath) {
          debugLog('콜백 URL 감지', { 
            pathname: window.location.pathname,
            includes_en: window.location.pathname.includes('/en/auth/callback/')
          });
          
          // 로그인 상태 설정
          localStorage.setItem('login_callback_detected', 'true');
          localStorage.setItem('login_callback_time', Date.now().toString());
          localStorage.setItem('login_callback_path', window.location.pathname);
        }
        
        // 현재 URL 검사
        const url = new URL(window.location.href);
        const code = url.searchParams.get('code');
        const state = url.searchParams.get('state');
        const error = url.searchParams.get('error');
        const errorDescription = url.searchParams.get('error_description');
        
        // State 값에서 언어 정보 확인 (리디렉션 시 활용)
        let language = 'en'; // 기본값
        try {
          if (state) {
            const stateData = JSON.parse(state);
            language = stateData.lang || 'en';
            debugLog('State에서 언어 정보 추출', { lang: language, stateData });
          }
        } catch (e) {
          // State 파싱 오류 무시
        }
        
        // 오류 파라미터가 있는지 확인
        if (error) {
          console.error('URL에서 OAuth 오류 파라미터 감지:', error, errorDescription);
          setError(`OAuth 인증 오류: ${errorDescription || error}`);
          setLoading(false);
          processingRef.current = false;
          return;
        }
        
        // 코드가 있는 경우만 처리
        if (code) {
          // state 값을 확인하여 추가 정보 추출
          let stateData: any = null;
          try {
            if (state) {
              stateData = JSON.parse(state);
              debugLog('인증 코드 state 데이터', stateData);
            }
          } catch (e) {
            debugLog('state 파싱 오류', { state, error: e instanceof Error ? e.message : 'Unknown error' });
          }
          
          debugLog('인증 코드 감지', {
            codePrefix: code.substring(0, 5) + '...',
            state,
            url: window.location.href
          });
          
          // URL에서 코드 제거 (히스토리에 남지 않도록)
          // 경로 보존: 원래 경로로 돌아갈 수 있도록 pathname만 남김
          window.history.replaceState({}, document.title, window.location.pathname);
          
          // 콜백 처리 기록
          try {
            localStorage.setItem('auth_callback_processing', 'true');
            localStorage.setItem('auth_callback_time', Date.now().toString());
            
            if (stateData) {
              localStorage.setItem('auth_state_data', JSON.stringify(stateData));
            }
          } catch (e) {
            // 저장 오류 무시
          }
          
          try {
            // 세션 교환 시작 로그
            debugLog('세션 교환 시작', { codePrefix: code.substring(0, 5) + '...' });
            
            // 수동으로 코드 교환 시도
            const { data, error } = await supabase.auth.exchangeCodeForSession(code);
            
            if (error) {
              console.error('세션 교환 오류:', error.message);
              debugLog('세션 교환 오류', { error: error.message });
              
              // 오류 설정하고 로딩 상태 해제
              setError('로그인 처리 중 오류가 발생했습니다: ' + error.message);
              setLoading(false);
              processingRef.current = false;
              
              try {
                localStorage.setItem('auth_callback_error', error.message);
                localStorage.setItem('auth_callback_error_time', Date.now().toString());
              } catch (e) {
                // 저장 오류 무시
              }
              
              // 5초 후 페이지 새로고침 (가끔 오류 후에도 세션이 설정됨)
              setTimeout(() => {
                window.location.reload();
              }, 5000);
              
              return;
            }
            
            if (data?.session) {
              debugLog('세션 교환 성공', { userId: data.session.user?.id });
              
              // 수동으로 세션 설정
              await supabase.auth.setSession({
                access_token: data.session.access_token,
                refresh_token: data.session.refresh_token,
              });
              
              // 인증 성공 기록
              try {
                localStorage.setItem('auth_session_obtained', 'true');
                localStorage.setItem('auth_session_time', Date.now().toString());
                localStorage.setItem('auth_provider', stateData?.provider || 'oauth');
              } catch (e) {
                // 저장 오류 무시
              }
              
              // 인증 이벤트 발생
              window.dispatchEvent(new Event('auth.state.changed'));
              
              // 약간의 지연 후 홈으로 리디렉션 (이벤트가 처리될 시간을 주기 위함)
              setTimeout(() => {
                debugLog('로그인 완료, 홈으로 이동');
                // 언어 정보를 사용하여 올바른 경로로 리디렉션
                window.location.href = `/${language}`;
              }, 500);
              
              return;
            } else {
              // 세션이 없는 경우 로딩 상태 해제
              console.warn('세션 교환은 성공했으나 세션이 없음');
              debugLog('세션 없음', { data });
              
              setLoading(false);
              processingRef.current = false;
              
              try {
                localStorage.setItem('auth_no_session', 'true');
                localStorage.setItem('auth_no_session_time', Date.now().toString());
              } catch (e) {
                // 저장 오류 무시
              }
              
              // 3초 후 페이지 새로고침
              setTimeout(() => {
                console.log('세션 없음 - 페이지 새로고침');
                window.location.reload();
              }, 3000);
              
              return;
            }
          } catch (err: any) {
            console.error('세션 교환 중 예외 발생:', err);
            debugLog('세션 교환 예외', { error: err?.message });
            setError('로그인 처리 중 오류가 발생했습니다');
            setLoading(false);
            processingRef.current = false;
            
            try {
              localStorage.setItem('auth_callback_exception', err?.message || 'Unknown error');
              localStorage.setItem('auth_callback_exception_time', Date.now().toString());
            } catch (e) {
              // 저장 오류 무시
            }
            
            // 5초 후 페이지 새로고침 (가끔 오류 후에도 세션이 설정됨)
            setTimeout(() => {
              console.log('오류 후 페이지 새로고침');
              window.location.reload();
            }, 5000);
            
            return;
          }
        }
      }
      
      // 코드가 없는 경우, 현재 인증 상태 확인
      await checkAuth();
      processingRef.current = false;
    } catch (e: any) {
      console.error('인증 코드 확인 중 오류:', e);
      debugLog('인증 코드 확인 오류', { error: e?.message });
      
      try {
        localStorage.setItem('auth_code_check_error', e?.message || 'Unknown error');
        localStorage.setItem('auth_code_check_error_time', Date.now().toString());
      } catch (storageErr) {
        // 저장 오류 무시
      }
      
      // 에러 발생시 반드시 로딩 상태 해제
      setLoading(false);
      processingRef.current = false;
    }
  }, [supabase, checkAuth]);

  // Apple 로그인 처리 함수
  const handleAppleSignIn = useCallback(async (appleSDKInitialized: boolean, sdkScriptLoaded: boolean) => {
    if (!window.AppleID || !appleSDKInitialized) {
      if (sdkScriptLoaded && !window.AppleID) {
        setError('이 브라우저에서는 Apple 로그인이 지원되지 않습니다. 다른 로그인 방법을 이용하세요.');
      } else {
        setError('Apple 로그인이 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요.');
      }
      return;
    }

    try {
      setLoading(true);
      
      // ID 토큰 획득
      const appleResponse = await window.AppleID.auth.signIn();
      if (!appleResponse.authorization.id_token) {
        throw new Error('Apple에서 ID 토큰을 받지 못했습니다.');
      }

      const idToken = appleResponse.authorization.id_token;
      
      // Supabase로 인증 시도
      try {
        const { data, error } = await supabase.auth.signInWithIdToken({
          provider: 'apple',
          token: idToken
        });
        
        if (!error) {
          return handleAuthSuccess(data, 'apple');
        }
        
        // 첫 번째 시도 실패 시, nonce를 명시적으로 null로 설정하여 재시도
        if (error.message?.includes('nonce') || error.message?.includes('Nonce')) {
          const { data: retryData, error: retryError } = await supabase.auth.signInWithIdToken({
            provider: 'apple',
            token: idToken,
            nonce: null
          });
          
          if (!retryError) {
            return handleAuthSuccess(retryData, 'apple');
          }
          
          // 마지막 시도
          const { data: finalData, error: finalError } = await supabase.auth.signInWithIdToken({
            provider: 'apple',
            token: idToken
          });
          
          if (!finalError) {
            return handleAuthSuccess(finalData, 'apple');
          }
          
          setError(`Apple 로그인에 실패했습니다: ${finalError.message}`);
        } else {
          setError(`Apple 로그인에 실패했습니다: ${error.message}`);
        }
      } catch (error: any) {
        setError(`Apple 로그인 처리 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      }
    } catch (err: any) {
      setError(`Apple 로그인 처리 중 오류가 발생했습니다: ${err.message || '알 수 없는 오류'}`);
    } finally {
      setLoading(false);
    }
  }, [supabase, handleAuthSuccess]);

  // Google 로그인 처리 함수
  const handleGoogleSignIn = useCallback(async () => {
    try {
      // 로딩 상태 설정 - 로그인 폼 숨김
      setLoading(true);
      
      // URL 환경 직접 감지 (window.location 객체 사용)
      const actualOrigin = window.location.origin;
      const actualHost = window.location.host;
      const actualHostname = window.location.hostname;
      const actualProtocol = window.location.protocol;
      const actualPathname = window.location.pathname;
      
      // 현재 언어 감지 - 경로에서 언어 코드 추출
      const langMatch = actualPathname.match(/^\/([a-z]{2})\//);
      const currentLang = langMatch ? langMatch[1] : 'en';
      
      // PKCE 코드 검증자 및 챌린지 생성
      const codeVerifier = generateCodeVerifier();
      const codeChallenge = await generateCodeChallenge(codeVerifier);
      
      // 코드 검증자를 로컬 스토리지에 저장 (나중에 검증 시 사용)
      storeCodeVerifier(codeVerifier);
      
      // 디버깅 정보 저장
      debugLog('URL 정보 및 PKCE 설정', {
        actualOrigin,
        actualHost,
        actualHostname,
        actualProtocol,
        currentLang,
        href: window.location.href,
        codeChallengeLength: codeChallenge.length,
        codeVerifierLength: codeVerifier.length
      });
      
      // 환경 정보 로컬 스토리지에 저장 (인증 후 비교용)
      try {
        localStorage.setItem('auth_request_info', JSON.stringify({
          actualOrigin,
          actualHost,
          actualHostname,
          language: currentLang,
          timestamp: Date.now(),
          pkce: true
        }));
      } catch (e) {
        // 저장 실패 시 무시
      }
      
      // ngrok 환경 직접 확인
      const isNgrokActual = 
        actualHostname.includes('ngrok') || 
        actualHost.includes('ngrok') ||
        /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(actualHostname);
      
      debugLog('ngrok 환경 감지', {
        isNgrokActual,
        hostnameCheck: actualHostname.includes('ngrok'),
        hostCheck: actualHost.includes('ngrok'),
        regexCheck: /^[a-z0-9]+\.ngrok(?:-free)?\.(?:io|app)$/.test(actualHostname)
      });
      
      // 오류 로깅 함수
      const logError = (message: string, error: any) => {
        console.error(message, error);
        debugLog('구글 OAuth 오류', { message, error });
        setError(message);
        setLoading(false);
      };
      
      // 먼저 Supabase 세션을 클리어 (기존 인증 상태로 인한 문제 방지)
      try {
        await supabase.auth.signOut({ scope: 'local' });
        debugLog('기존 세션 클리어');
      } catch (e) {
        debugLog('기존 세션 클리어 실패', { error: e });
        // 실패해도 계속 진행
      }
      
      // NgRok 환경 또는 일반 환경 모두 직접 Google OAuth URL 구성 사용
      // 콜백 URL 동적 생성 (현재 환경과 언어 고려)
      const callbackPath = `${actualOrigin}/${currentLang}/auth/callback/google`;
      
      // GoogleAuth 엔드포인트 URL
      debugLog('직접 Google OAuth URL 구성 시작 (PKCE 적용)', {
        callbackPath,
        environment: isNgrokActual ? 'ngrok' : 'standard'
      });
      
      // 구글 OAuth URL 직접 구성
      const googleAuthUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
      
      // 필수 파라미터 설정
      googleAuthUrl.searchParams.append('client_id', '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com');
      
      // 콜백 URL 직접 설정 (Supabase가 아닌 우리 앱 URL 사용)
      googleAuthUrl.searchParams.append('redirect_uri', callbackPath);
      
      googleAuthUrl.searchParams.append('response_type', 'code');
      googleAuthUrl.searchParams.append('scope', 'email profile openid');
      googleAuthUrl.searchParams.append('access_type', 'offline');
      googleAuthUrl.searchParams.append('prompt', 'select_account');
      
      // PKCE 파라미터 추가
      googleAuthUrl.searchParams.append('code_challenge', codeChallenge);
      googleAuthUrl.searchParams.append('code_challenge_method', 'S256');
      
      // state 파라미터에 중요한 정보를 포함
      const stateData = {
        timestamp: Date.now(),
        origin: actualOrigin,
        host: actualHost,
        returnTo: callbackPath,
        provider: 'google',
        lang: currentLang,
        pkce: true, // PKCE 사용 여부 표시
        direct: true // 직접 OAuth URL 사용 표시
      };
      
      googleAuthUrl.searchParams.append('state', JSON.stringify(stateData));
      
      // 로그 및 디버깅
      debugLog('Google OAuth URL 구성 완료 (PKCE 적용)', { 
        url: googleAuthUrl.toString(),
        hasCodeChallenge: !!codeChallenge,
        hasCodeVerifier: !!codeVerifier,
        redirect_uri: callbackPath
      });
      console.log('Google 인증 페이지로 이동:', googleAuthUrl.toString());
      
      // 로컬 스토리지에 정보 저장 (디버깅용)
      try {
        localStorage.setItem('last_oauth_request', JSON.stringify({
          provider: 'google',
          timestamp: Date.now(),
          url: googleAuthUrl.toString(),
          state: stateData,
          pkce: true,
          direct_redirect: true
        }));
      } catch (e) {
        // 저장 실패해도 계속 진행
      }
      
      // 약간의 지연 후 리디렉션 (브라우저 처리 시간 확보)
      setTimeout(() => {
        window.location.href = googleAuthUrl.toString();
      }, 100);
    } catch (error: any) {
      console.error('구글 로그인 예외:', error);
      debugLog('구글 로그인 예외', { error: error?.message });
      clearCodeVerifier(); // 예외 발생 시 검증자 정리
      setError(`구글 로그인 중 예기치 않은 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      setLoading(false);
    }
  }, [supabase, handleAuthSuccess]);

  // 기타 소셜 로그인 처리 함수 (카카오, 위챗)
  const handleOtherProviderSignIn = useCallback(async (provider: 'kakao' | 'wechat') => {
    try {
      // 로딩 상태 설정 - 로그인 폼 숨김
      setLoading(true);
      
      const res = await fetch(
        `https://api.picnic.fan/functions/v1/${provider}-web-oauth`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            redirect_url: window.location.origin + '/auth/callback/' + provider,
          }),
          credentials: 'include',
        },
      );

      if (!res.ok) {
        setError(`${provider} 로그인 중 오류가 발생했습니다.`);
        setLoading(false);
        return;
      }

      const { url, error: oauthError } = await res.json();

      if (oauthError || !url) {
        setError(`${provider} 로그인 중 오류가 발생했습니다: ${oauthError || '알 수 없는 오류'}`);
        setLoading(false);
        return;
      }

      // 소셜 제공자 로그인 페이지로 이동
      window.location.href = url;
    } catch (error: any) {
      setError(`${provider} 로그인 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`);
      setLoading(false);
    }
  }, []);

  // 통합된 로그인 처리 함수
  const handleSignIn = useCallback((provider: SocialProvider, appleSDKInitialized: boolean, sdkScriptLoaded: boolean) => {
    if (provider === 'apple') {
      handleAppleSignIn(appleSDKInitialized, sdkScriptLoaded);
    } else if (provider === 'google') {
      handleGoogleSignIn();
    } else {
      handleOtherProviderSignIn(provider);
    }
  }, [handleAppleSignIn, handleGoogleSignIn, handleOtherProviderSignIn]);

  // 에러 파라미터 처리 및 URL 정리
  const processErrorParams = useCallback(() => {
    if (typeof window === 'undefined') return;
    
    const url = new URL(window.location.href);
    const error = url.searchParams.get('error');
    const errorDescription = url.searchParams.get('error_description');
    const provider = url.searchParams.get('provider');
    const authError = url.searchParams.get('auth_error');
    
    // 오류 로컬 스토리지에서 확인
    const localErrorDescription = (() => {
      try {
        return localStorage.getItem('auth_error_description');
      } catch (e) {
        return null;
      }
    })();
    
    if (authError === 'true' || error) {
      // 오류 메시지 설정
      if (errorDescription) {
        setError(`인증 오류: ${decodeURIComponent(errorDescription)}`);
      } else if (localErrorDescription) {
        setError(`인증 오류: ${localErrorDescription}`);
        // 로컬 스토리지에서 사용 후 제거
        try {
          localStorage.removeItem('auth_error_description');
        } catch (e) {}
      } else if (error === 'invalid_request' || error === 'bad_oauth_callback') {
        setError('OAuth 인증 중 문제가 발생했습니다. 다시 시도해주세요.');
      } else if (error) {
        switch (error) {
          case 'missing_params':
            setError('필수 파라미터가 누락되었습니다.');
            break;
          case 'server_error':
            setError(`서버 오류가 발생했습니다: ${errorDescription || '알 수 없는 오류'}`);
            break;
          case 'oauth_error':
            setError(provider === 'apple' 
              ? 'Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요.'
              : '소셜 로그인 중 오류가 발생했습니다.');
            break;
          case 'callback_error':
            setError('인증 처리 중 오류가 발생했습니다.');
            break;
          default:
            setError(`인증 오류가 발생했습니다: ${errorDescription || '알 수 없는 오류'}`);
        }
      } else {
        setError('로그인 중 알 수 없는 오류가 발생했습니다. 다시 시도해주세요.');
      }
      
      // URL에서 오류 파라미터 제거
      url.searchParams.delete('error');
      url.searchParams.delete('error_description');
      url.searchParams.delete('auth_error');
      url.searchParams.delete('provider');
      window.history.replaceState({}, document.title, url.toString());
    }
  }, []);

  return {
    error,
    loading,
    supabase,
    setError,
    setLoading,
    handleSignIn,
    checkForAuthCode,
    checkAuth,
    processErrorParams,
  };
}; 