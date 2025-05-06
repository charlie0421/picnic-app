'use client';

import { useEffect } from 'react';
import { supabase } from '@/utils/supabase-client';

export default function Root() {
  // 컴포넌트 마운트 시 URL 코드 확인
  useEffect(() => {
    const handleAuthCodeInUrl = async () => {
      try {
        // 브라우저 환경인지 확인
        if (typeof window === 'undefined') return;
        
        // URL에서 파라미터 확인
        const url = new URL(window.location.href);
        const code = url.searchParams.get('code');
        const error = url.searchParams.get('error');
        const errorDescription = url.searchParams.get('error_description');
        const state = url.searchParams.get('state');
        
        console.log('URL 파라미터 확인:', {
          hasCode: !!code,
          hasError: !!error,
          hasState: !!state,
          url: window.location.href,
          pathname: window.location.pathname,
          host: window.location.host
        });
        
        // 현재 URL이 api.picnic.fan 인지 확인
        const isApiPicnicFan = window.location.hostname === 'api.picnic.fan';
        if (isApiPicnicFan) {
          console.log('api.picnic.fan 도메인 감지. 이 페이지에서는 처리하지 않음');
          return;
        }
        
        // 오류 파라미터가 있는 경우 처리
        if (error) {
          console.error('인증 오류 감지:', error, errorDescription);
          
          // 오류 정보 저장
          try {
            localStorage.setItem('auth_error', error);
            localStorage.setItem('auth_error_description', errorDescription || '알 수 없는 오류');
            localStorage.setItem('auth_error_timestamp', Date.now().toString());
          } catch (e) {
            // 저장 실패해도 계속 진행
          }
          
          // URL에서 오류 파라미터 제거
          window.history.replaceState({}, document.title, window.location.pathname);
          
          // 로그인 페이지로 리디렉션
          setTimeout(() => {
            window.location.href = '/login?auth_error=true&error_description=' + encodeURIComponent(errorDescription || '알 수 없는 오류');
          }, 100);
          
          return;
        }
        
        // 인증 코드가 있는 경우 처리
        if (code) {
          // 코드 타입 확인 (길이 또는 형식으로 구분)
          const isSupabaseCode = code.includes('-') && code.length > 30;
          const isGoogleCode = code.startsWith('4/0') || !code.includes('-');
          
          console.log('인증 코드 감지:', {
            codePrefix: code.substring(0, 5) + '...',
            isSupabaseCode,
            isGoogleCode,
            hasState: !!state
          });
          
          try {
            // localStorage에 시도 기록
            localStorage.setItem('auth_code_detected', 'true');
            localStorage.setItem('auth_code_timestamp', Date.now().toString());
            localStorage.setItem('auth_code_type', isSupabaseCode ? 'supabase' : (isGoogleCode ? 'google' : 'unknown'));
          } catch (e) {
            // 저장 실패해도 계속 진행
          }
          
          // URL에서 코드 파라미터 제거 (히스토리에 남지 않도록)
          window.history.replaceState({}, document.title, window.location.pathname);
          
          // 코드를 세션으로 직접 교환
          try {
            console.log('인증 코드를 세션으로 교환 시도...');
            const { data, error } = await supabase.auth.exchangeCodeForSession(code);
            
            if (error) {
              console.error('세션 교환 오류:', error);
              
              // 로그인 페이지로 리디렉션
              setTimeout(() => {
                window.location.href = '/login?auth_error=true&error_description=' + encodeURIComponent(error.message || '세션 교환 오류');
              }, 100);
              
              return;
            }
            
            if (data.session) {
              console.log('세션 교환 성공:', {
                userId: data.session.user?.id
              });
              
              // localStorage에 성공 표시
              try {
                localStorage.setItem('auth_success', 'true');
                localStorage.setItem('auth_provider', data.session.user?.app_metadata?.provider || 'unknown');
                localStorage.setItem('auth_timestamp', Date.now().toString());
              } catch (e) {
                // 실패해도 진행
              }
              
              // 인증 이벤트 발생
              window.dispatchEvent(new Event('auth.state.changed'));
              
              // 홈으로 리디렉션
              setTimeout(() => {
                window.location.href = '/';
              }, 500);
            } else {
              console.warn('세션 교환은 성공했으나 세션이 없음');
              
              // 로그인 페이지로 리디렉션
              setTimeout(() => {
                window.location.href = '/login?auth_error=true&error_description=세션이 생성되지 않았습니다';
              }, 100);
            }
          } catch (error) {
            console.error('세션 교환 중 예외 발생:', error);
            
            // 로그인 페이지로 리디렉션
            setTimeout(() => {
              window.location.href = '/login?auth_error=true&error_description=세션 교환 중 오류가 발생했습니다';
            }, 100);
          }
        }
      } catch (error) {
        console.error('인증 코드 처리 중 오류:', error);
      }
    };
    
    // URL 코드 확인 실행
    handleAuthCodeInUrl();
  }, []);
  
  return null; // 이 컴포넌트는 UI를 렌더링하지 않음
}