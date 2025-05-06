'use client';

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '../utils/supabase-client';
import { Session, User as SupabaseUser } from '@supabase/supabase-js';
import { UserProfiles } from '@/types/interfaces';

// 인증 상태 인터페이스
export interface AuthState {
  isAuthenticated: boolean;
  user: UserProfiles | null;
  loading: boolean;
  error?: string | null;
}

interface AuthContextProps {
  authState: AuthState;
  signIn: (email: string, password: string) => Promise<void>;
  signInWithSocial: (provider: 'google' | 'apple' | 'kakao' | 'wechat') => Promise<void>;
  signOut: () => Promise<void>;
  signUp: (email: string, password: string, username: string) => Promise<void>;
  updateUserProfile: (profile: Partial<UserProfiles>) => Promise<void>;
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
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error) throw error;

      if (data) {
        return {
          ...data,
          avatarUrl: data.avatar_url,
          isAdmin: data.is_admin,
          createdAt: data.created_at,
          updatedAt: data.updated_at,
          deletedAt: data.deleted_at,
          birthDate: data.birth_date,
          birthTime: data.birth_time,
          openAges: data.open_ages,
          openBirthDate: data.open_ages,
          openBirthTime: data.open_ages,
          openGender: data.open_ages,
          starCandy: data.star_candy,
          starCandyBonus: data.star_candy_bonus
        };
      }
      return null;
    } catch (error) {
      console.error('사용자 프로필 조회 오류:', error);
      return null;
    }
  }, []);

  // 세션 변경 처리
  const handleSession = useCallback(async (session: Session | null) => {
    if (session) {
      const userProfile = await fetchUserProfile(session.user);

      setAuthState((prev: AuthState) => ({
        ...prev,
        isAuthenticated: true,
        user: userProfile || {
          id: session.user.id,
          email: session.user.email || null,
          nickname: null,
          avatarUrl: null,
          bio: null,
          isAdmin: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          deletedAt: null,
          birthDate: null,
          birthTime: null,
          gender: null,
          openAges: false,
          openBirthDate: false,
          openBirthTime: false,
          openGender: false,
          starCandy: 0,
          starCandyBonus: 0
        },
        loading: false,
        error: null
      }));
    } else {
      setAuthState((prev: AuthState) => ({
        ...prev,
        isAuthenticated: false,
        user: null,
        loading: false,
        error: null
      }));
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
        setAuthState((prev: AuthState) => ({
          ...prev,
          isAuthenticated: false,
          user: null,
          loading: false,
          error: '인증 상태 확인 중 오류가 발생했습니다.',
        }));
      }
    };

    // 인증 상태 변화 구독
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event: 'SIGNED_IN' | 'SIGNED_OUT' | 'USER_UPDATED' | 'TOKEN_REFRESHED' | 'PASSWORD_RECOVERY', session: Session | null) => {
      console.log('Auth State Change:', event, !!session);
      await handleSession(session);
    });

    // 커스텀 이벤트 리스너 (외부에서 강제로 인증 상태 갱신을 요청할 수 있도록)
    const handleAuthStateChanged = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        await handleSession(session);
      } catch (error) {
        console.error('이벤트 기반 인증 체크 에러:', error);
      }
    };

    // 커스텀 이벤트 리스너 등록
    window.addEventListener('auth.state.changed', handleAuthStateChanged);

    checkUser();

    // 클린업 함수
    return () => {
      subscription?.unsubscribe();
      window.removeEventListener('auth.state.changed', handleAuthStateChanged);
    };
  }, [handleSession]);

  const signIn = useCallback(async (email: string, password: string) => {
    try {
      setAuthState((prev: AuthState) => ({ ...prev, loading: true, error: null }));
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (error: any) {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        error: error.message || '로그인 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signInWithSocial = useCallback(async (provider: 'google' | 'apple' | 'kakao' | 'wechat') => {
    try {
      setAuthState((prev: AuthState) => ({ ...prev, loading: true, error: null }));
      
      const options = {
        redirectTo: window.location.origin + '/auth/callback',
      };
      
      const { error } = await supabase.auth.signInWithOAuth({ 
        provider, 
        options 
      });
      
      if (error) throw error;
    } catch (error: any) {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        error: error.message || '소셜 로그인 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      setAuthState((prev: AuthState) => ({ ...prev, loading: true, error: null }));
      
      // 모든 세션 제거
      const { error } = await supabase.auth.signOut({
        scope: 'global'
      });
      
      if (error) throw error;
      
      // 로컬 스토리지의 세션 데이터도 제거
      localStorage.removeItem('supabase.auth.token');
      
      // 상태 초기화
      setAuthState({
        isAuthenticated: false,
        user: null,
        loading: false,
        error: null,
      });
      
    } catch (error: any) {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        error: error.message || '로그아웃 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const signUp = useCallback(async (email: string, password: string, username: string) => {
    try {
      setAuthState((prev: AuthState) => ({ ...prev, loading: true, error: null }));
      
      const { data, error } = await supabase.auth.signUp({ email, password });
      
      if (error) throw error;
      
      if (data.user) {
        const { error: profileError } = await supabase
          .from('user_profiles')
          .insert([
            {
              id: data.user.id,
              email: email,
              nickname: username,
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            }
          ]);
          
        if (profileError) throw profileError;
      }
    } catch (error: any) {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        error: error.message || '회원가입 중 오류가 발생했습니다.',
      }));
    }
  }, []);

  const updateUserProfile = useCallback(async (profile: Partial<UserProfiles>) => {
    try {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: true,
        error: null,
      }));
      
      const currentUserId = authState.user?.id;
      if (!currentUserId) {
        throw new Error('로그인이 필요합니다');
      }
      
      const { error } = await supabase
        .from('user_profiles')
        .update(profile)
        .eq('id', currentUserId);
        
      if (error) throw error;
      
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        user: prev.user ? { ...prev.user, ...profile } : null
      }));
      
    } catch (error: any) {
      setAuthState((prev: AuthState) => ({
        ...prev,
        loading: false,
        error: error.message || '프로필 업데이트 중 오류가 발생했습니다.',
      }));
    }
  }, [authState.user?.id]);

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