'use client';

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '../utils/supabase';
import { AuthState, UserInfo, mapUserFromSupabase } from '../types/user';
import { Session, User as SupabaseUser } from '@supabase/supabase-js';

interface AuthContextProps {
  authState: AuthState;
  signIn: (email: string, password: string) => Promise<void>;
  signInWithSocial: (provider: 'google' | 'apple' | 'kakao') => Promise<void>;
  signOut: () => Promise<void>;
  signUp: (email: string, password: string, username: string) => Promise<void>;
  updateUserProfile: (profile: Partial<UserInfo>) => Promise<void>;
}

const AuthContext = createContext<AuthContextProps | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [authState, setAuthState] = useState<AuthState>({
    isAuthenticated: false,
    user: null,
    loading: true,
    error: null,
  });

  // 사용자 프로필 정보 가져오기
  const fetchUserProfile = useCallback(async (user: SupabaseUser) => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error) throw error;

      return data ? mapUserFromSupabase(data) : null;
    } catch (error) {
      console.error('사용자 프로필 조회 오류:', error);
      return null;
    }
  }, []);

  // 세션 변경 처리
  const handleSession = useCallback(async (session: Session | null) => {
    if (session) {
      const userProfile = await fetchUserProfile(session.user);

      setAuthState({
        isAuthenticated: true,
        user: userProfile || {
          id: session.user.id,
          email: session.user.email,
        },
        loading: false,
        error: null,
      });
    } else {
      setAuthState({
        isAuthenticated: false,
        user: null,
        loading: false,
        error: null,
      });
    }
  }, [fetchUserProfile]);

  useEffect(() => {
    // 초기 인증 상태 확인
    const checkUser = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        await handleSession(session);
      } catch (error) {
        console.error('인증 체크 에러:', error);
        setAuthState({
          isAuthenticated: false,
          user: null,
          loading: false,
          error: '인증 상태 확인 중 오류가 발생했습니다.',
        });
      }
    };

    // 인증 상태 변화 구독
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_, session) => {
      await handleSession(session);
    });

    checkUser();

    // 클린업 함수
    return () => {
      subscription?.unsubscribe();
    };
  }, [handleSession]);

  const signIn = useCallback(async (email: string, password: string) => {
    try {
      setAuthState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message || '로그인 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signInWithSocial = useCallback(async (provider: 'google' | 'apple' | 'kakao') => {
    try {
      setAuthState(prev => ({ ...prev, loading: true, error: null }));
      
      // 각 소셜 로그인에 맞는 옵션 설정
      const options = {
        redirectTo: window.location.origin + '/auth/callback',
      };
      
      const { error } = await supabase.auth.signInWithOAuth({ 
        provider, 
        options 
      });
      
      if (error) throw error;
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message || '소셜 로그인 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      setAuthState(prev => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message || '로그아웃 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signUp = useCallback(async (email: string, password: string, username: string) => {
    try {
      setAuthState(prev => ({ ...prev, loading: true, error: null }));
      
      // 이메일 회원가입
      const { data, error } = await supabase.auth.signUp({ email, password });
      
      if (error) throw error;
      
      if (data.user) {
        // 사용자 프로필 생성
        const { error: profileError } = await supabase
          .from('users')
          .insert([
            {
              id: data.user.id,
              email: email,
              username: username,
              display_name: username,
              created_at: new Date().toISOString()
            }
          ]);
          
        if (profileError) throw profileError;
      }
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message || '회원가입 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const updateUserProfile = useCallback(async (profile: Partial<UserInfo>) => {
    try {
      setAuthState(prev => {
        // 먼저 로딩 상태 설정
        return { ...prev, loading: true, error: null };
      });
      
      // 최신 authState를 가져오기 위해 함수형 업데이트 사용
      const currentUserId = authState.user?.id;
      if (!currentUserId) {
        throw new Error('로그인이 필요합니다');
      }
      
      // Supabase 테이블 컬럼명으로 변환
      const supabaseProfile = {
        username: profile.username,
        display_name: profile.displayName,
        avatar_url: profile.avatarUrl,
        bio: profile.bio,
        updated_at: new Date().toISOString()
      };
      
      const { error } = await supabase
        .from('users')
        .update(supabaseProfile)
        .eq('id', currentUserId);
        
      if (error) throw error;
      
      // 성공 시 프로필 정보 업데이트
      setAuthState(prev => ({
        ...prev,
        loading: false,
        user: prev.user ? { ...prev.user, ...profile } : null
      }));
      
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message || '프로필 업데이트 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  return (
    <AuthContext.Provider value={{ 
      authState, 
      signIn, 
      signInWithSocial,
      signOut, 
      signUp,
      updateUserProfile
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 