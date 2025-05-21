'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { User, Session, Provider } from '@supabase/supabase-js';
import { createBrowserSupabaseClient, signOut as supabaseSignOut } from './client';
import { Database } from '@/types/supabase';
import { UserProfiles } from '@/types/interfaces';

// 프로필 캐시 저장소 (메모리 내 캐싱)
const profileCache = new Map<string, { profile: UserProfiles; timestamp: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5분 캐시

type AuthContextType = {
  // 기본 인증 상태
  user: User | null;
  userProfile: UserProfiles | null;
  session: Session | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  isInitialized: boolean;
  error: string | null;
  
  // 인증 메서드
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signInWithOAuth: (provider: 'google' | 'apple' | 'kakao' | 'wechat') => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, username?: string) => Promise<{ error: Error | null, data: { user: User | null } }>;
  signOut: () => Promise<{ success: boolean; error?: unknown }>;
  refreshSession: () => Promise<void>;
  
  // 프로필 관리
  updateUserProfile: (profile: Partial<UserProfiles>) => Promise<{ success: boolean; error?: unknown }>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

type AuthProviderProps = {
  children: React.ReactNode;
  initialSession?: Session | null;
};

export function AuthProvider({
  children,
  initialSession,
}: AuthProviderProps) {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const [session, setSession] = useState<Session | null>(initialSession || null);
  const [user, setUser] = useState<User | null>(initialSession?.user || null);
  const [userProfile, setUserProfile] = useState<UserProfiles | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(!!session?.user);
  const [lastProfileFetch, setLastProfileFetch] = useState<Record<string, number>>({});

  // 사용자 프로필 정보 가져오기
  const fetchUserProfile = useCallback(async (userId: string) => {
    try {
      // 이미 최근에 요청했는지 확인 (1초 이내 중복 요청 방지)
      const now = Date.now();
      const lastFetch = lastProfileFetch[userId] || 0;
      if (now - lastFetch < 1000) {
        console.log('🔍 프로필 요청 건너뜀: 최근에 이미 요청됨', userId);
        return userProfile;
      }
      
      // 캐시에서 확인
      const cached = profileCache.get(userId);
      if (cached && now - cached.timestamp < CACHE_TTL) {
        console.log('🔍 캐시된 프로필 사용:', userId);
        setUserProfile(cached.profile);
        return cached.profile;
      }
      
      // 요청 타임스탬프 기록
      setLastProfileFetch(prev => ({ ...prev, [userId]: now }));
      
      console.log('🔍 프로필 서버에서 가져오기:', userId);
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) throw error;

      if (data) {
        const profile = {
          id: data.id,
          email: data.email,
          nickname: data.nickname,
          avatarUrl: data.avatar_url,
          isAdmin: data.is_admin,
          createdAt: data.created_at,
          updatedAt: data.updated_at,
          deletedAt: data.deleted_at,
          birthDate: data.birth_date,
          birthTime: data.birth_time,
          gender: data.gender,
          openAges: data.open_ages,
          openGender: data.open_gender,
          starCandy: data.star_candy,
          starCandyBonus: data.star_candy_bonus
        } as UserProfiles;
        
        // 캐시에 저장
        profileCache.set(userId, { profile, timestamp: now });
        
        setUserProfile(profile);
        return profile;
      }
      
      // 프로필이 없으면 기본 정보로 빈 프로필 생성 (현재 사용자에 대해)
      if (session?.user?.id === userId) {
        const defaultProfile: UserProfiles = {
          id: userId,
          email: session.user.email || null,
          nickname: null,
          avatarUrl: null,
          isAdmin: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          deletedAt: null,
          birthDate: null,
          birthTime: null,
          gender: null,
          openAges: false,
          openGender: false,
          starCandy: 0,
          starCandyBonus: 0
        };
        
        // 캐시에 저장
        profileCache.set(userId, { profile: defaultProfile, timestamp: now });
        
        setUserProfile(defaultProfile);
        return defaultProfile;
      }
      
      setUserProfile(null);
      return null;
    } catch (error) {
      console.error('사용자 프로필 조회 오류:', error);
      setUserProfile(null);
      return null;
    }
  }, [supabase, session, userProfile, lastProfileFetch]);

  // 인증 상태 처리 함수
  const handleSession = useCallback(async (newSession: Session | null) => {
    setSession(newSession);
    setUser(newSession?.user ?? null);
    setIsAuthenticated(!!newSession?.user);
    
    // 세션이 있으면 사용자 프로필 로드
    if (newSession?.user) {
      await fetchUserProfile(newSession.user.id);
    } else {
      setUserProfile(null);
    }
    
    setIsLoading(false);
    setError(null);
  }, [fetchUserProfile]);

  // 세션 갱신 및 프로필 로드
  useEffect(() => {
    let isMounted = true;
    
    const loadUserSession = async () => {
      try {
        setIsLoading(true);
        console.log('🔍 AuthProvider: 세션 및 사용자 정보 로드 중...');
        
        // 현재 세션 가져오기
        const { data: { session: currentSession }, error } = await supabase.auth.getSession();
        
        if (error) {
          throw error;
        }
        
        // 컴포넌트가 언마운트되었으면 상태 업데이트 중단
        if (!isMounted) return;
        
        if (currentSession) {
          console.log('✅ AuthProvider: 세션 발견, 사용자 로그인 상태', currentSession.user.id);
          await handleSession(currentSession);
        } else {
          console.log('❌ AuthProvider: 세션 없음, 로그아웃 상태');
          setSession(null);
          setUser(null);
          setUserProfile(null);
          setIsAuthenticated(false);
        }
      } catch (error) {
        if (!isMounted) return;
        
        console.error('AuthProvider 초기화 오류:', error);
        setError(error instanceof Error ? error.message : String(error));
      } finally {
        if (isMounted) {
          setIsInitialized(true);
          setIsLoading(false);
        }
      }
    };

    loadUserSession();
    
    return () => {
      isMounted = false;
    };
  }, [handleSession, supabase.auth]);

  // 인증 상태 변경 구독
  useEffect(() => {
    console.log('🔄 AuthProvider: 인증 상태 변경 이벤트 구독 설정...');
    
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        console.log(`📣 AuthProvider: 인증 이벤트 감지: ${event}`, 
                    newSession ? `사용자 ID: ${newSession.user.id}` : '세션 없음');
        
        await handleSession(newSession);
        
        // 세션이 생성되었을 때 로컬 스토리지에 저장
        if (event === 'SIGNED_IN' && newSession) {
          try {
            localStorage.setItem('auth_success', 'true');
            localStorage.setItem('auth_provider', newSession.user?.app_metadata?.provider || 'unknown');
            localStorage.setItem('auth_timestamp', Date.now().toString());
          } catch (e) {
            console.warn('로컬 스토리지 저장 오류:', e);
          }
        }
      }
    );

    return () => {
      console.log('🛑 AuthProvider: 인증 이벤트 구독 해제');
      subscription.unsubscribe();
    };
  }, [supabase, handleSession]);

  // 캐시 정리 
  useEffect(() => {
    // 5분마다 만료된 캐시 항목 정리
    const cacheCleanupInterval = setInterval(() => {
      const now = Date.now();
      profileCache.forEach((cacheEntry, userId) => {
        if (now - cacheEntry.timestamp > CACHE_TTL) {
          profileCache.delete(userId);
        }
      });
    }, CACHE_TTL);
    
    return () => clearInterval(cacheCleanupInterval);
  }, []);

  const signIn = async (email: string, password: string) => {
    setIsLoading(true);
    setError(null);
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      return { error };
    } catch (error: any) {
      setError(error.message || '로그인 중 오류가 발생했습니다.');
      return { error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const signInWithOAuth = async (provider: 'google' | 'apple' | 'kakao' | 'wechat') => {
    setIsLoading(true);
    setError(null);
    try {
      console.log(`🔑 AuthProvider: ${provider} 소셜 로그인 시도...`);
      const { error } = await supabase.auth.signInWithOAuth({
        provider: provider as Provider,
        options: {
          redirectTo: `${window.location.origin}/auth/callback/${provider}`,
        },
      });
      
      if (error) throw error;
      return { error: null };
    } catch (error) {
      console.error(`AuthProvider: ${provider} 소셜 로그인 오류:`, error);
      setError(error instanceof Error ? error.message : String(error));
      return { error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const signUp = async (email: string, password: string, username?: string) => {
    setIsLoading(true);
    setError(null);
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });
      
      if (error) throw error;
      
      // 사용자 프로필 생성 (username이 제공된 경우)
      if (data.user && username) {
        try {
          const { error: profileError } = await supabase
            .from('user_profiles')
            .insert([
              {
                id: data.user.id,
                email: email,
                nickname: username,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              }
            ]);

          if (profileError) throw profileError;
        } catch (profileError: any) {
          console.error('프로필 생성 오류:', profileError);
          // 계정은 생성되었으므로 오류를 반환하지 않고 로그만 남김
        }
      }
      
      return { data, error: null };
    } catch (error: any) {
      setError(error.message || '회원가입 중 오류가 발생했습니다.');
      return { data: { user: null }, error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const refreshSession = async () => {
    try {
      const { data: { session: refreshedSession } } = await supabase.auth.refreshSession();
      await handleSession(refreshedSession);
    } catch (error: any) {
      console.error('세션 갱신 오류:', error);
      setError(error.message || '세션 갱신 중 오류가 발생했습니다.');
    }
  };
  
  const updateUserProfile = async (profile: Partial<UserProfiles>) => {
    try {
      setIsLoading(true);
      setError(null);

      const currentUserId = user?.id;
      if (!currentUserId) {
        throw new Error('로그인이 필요합니다');
      }

      // 데이터베이스 컬럼 명명 규칙에 맞게 변환
      const dbProfile: Record<string, any> = {};
      
      // snake_case로 변환
      if ('avatarUrl' in profile) dbProfile.avatar_url = profile.avatarUrl;
      if ('isAdmin' in profile) dbProfile.is_admin = profile.isAdmin;
      if ('createdAt' in profile) dbProfile.created_at = profile.createdAt;
      if ('updatedAt' in profile) dbProfile.updated_at = profile.updatedAt;
      if ('deletedAt' in profile) dbProfile.deleted_at = profile.deletedAt;
      if ('birthDate' in profile) dbProfile.birth_date = profile.birthDate;
      if ('birthTime' in profile) dbProfile.birth_time = profile.birthTime;
      if ('openAges' in profile) dbProfile.open_ages = profile.openAges;
      if ('openGender' in profile) dbProfile.open_gender = profile.openGender;
      if ('starCandy' in profile) dbProfile.star_candy = profile.starCandy;
      if ('starCandyBonus' in profile) dbProfile.star_candy_bonus = profile.starCandyBonus;
      
      // 일반 속성 복사
      if ('email' in profile) dbProfile.email = profile.email;
      if ('nickname' in profile) dbProfile.nickname = profile.nickname;
      if ('gender' in profile) dbProfile.gender = profile.gender;

      const { error } = await supabase
        .from('user_profiles')
        .update(dbProfile)
        .eq('id', currentUserId);

      if (error) throw error;

      // 업데이트된 프로필 객체 생성
      const updatedProfile = userProfile ? { ...userProfile, ...profile } : null;
      
      // 업데이트 성공시 상태 업데이트
      setUserProfile(updatedProfile);
      
      // 캐시 업데이트
      if (updatedProfile) {
        profileCache.set(currentUserId, { 
          profile: updatedProfile, 
          timestamp: Date.now() 
        });
        console.log('✅ 프로필 캐시 업데이트 완료:', currentUserId);
      }
      
      return { success: true };
    } catch (error: any) {
      setError(error.message || '프로필 업데이트 중 오류가 발생했습니다.');
      return { success: false, error };
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthContext.Provider 
      value={{
        user,
        userProfile,
        session,
        isLoading,
        isInitialized,
        isAuthenticated,
        error,
        signIn,
        signInWithOAuth,
        signUp,
        signOut: async () => await supabaseSignOut(),
        refreshSession,
        updateUserProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth는 AuthProvider 내에서 사용해야 합니다');
  }
  return context;
} 