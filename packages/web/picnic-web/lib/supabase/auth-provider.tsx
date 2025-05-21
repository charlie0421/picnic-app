'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { createBrowserSupabaseClient, signOut as supabaseSignOut } from './client';
import { Database } from '@/types/supabase';

type AuthContextType = {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  isInitialized: boolean;
  isAuthenticated: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signInWithOAuth: (provider: 'google' | 'apple' | 'kakao') => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string) => Promise<{ error: Error | null, data: { user: User | null } }>;
  signOut: () => Promise<{ success: boolean; error?: unknown }>;
  refreshSession: () => Promise<void>;
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
  const [isLoading, setIsLoading] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);

  // 세션이 있는지 확인
  const isAuthenticated = !!session?.user;

  useEffect(() => {
    // 현재 세션 가져오기
    const getActiveSession = async () => {
      try {
        setIsLoading(true);
        
        // 세션이 전달되지 않았다면 브라우저에서 세션 확인
        if (!initialSession) {
          const { data: { session: activeSession } } = await supabase.auth.getSession();
          setSession(activeSession);
          setUser(activeSession?.user || null);
        }
        
        setIsInitialized(true);
      } catch (error) {
        console.error('세션 로드 오류:', error);
      } finally {
        setIsLoading(false);
      }
    };
    
    getActiveSession();
    
    // 인증 상태 변경 구독
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, newSession) => {
        // 디버그 로깅
        if (process.env.NODE_ENV !== 'production') {
          console.log('인증 상태 변경:', event, !!newSession);
        }
        
        setSession(newSession);
        setUser(newSession?.user || null);
        setIsLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, [supabase, initialSession]);

  const signIn = async (email: string, password: string) => {
    setIsLoading(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      return { error };
    } catch (error) {
      return { error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const signInWithOAuth = async (provider: 'google' | 'apple' | 'kakao') => {
    setIsLoading(true);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: `${window.location.origin}/auth/callback/${provider}`,
        },
      });
      return { error };
    } catch (error) {
      return { error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const signUp = async (email: string, password: string) => {
    setIsLoading(true);
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });
      return { data, error };
    } catch (error) {
      return { data: { user: null }, error: error as Error };
    } finally {
      setIsLoading(false);
    }
  };

  const refreshSession = async () => {
    try {
      const { data: { session: refreshedSession } } = await supabase.auth.refreshSession();
      setSession(refreshedSession);
      setUser(refreshedSession?.user || null);
    } catch (error) {
      console.error('세션 갱신 오류:', error);
    }
  };

  return (
    <AuthContext.Provider 
      value={{
        user,
        session,
        isLoading,
        isInitialized,
        isAuthenticated,
        signIn,
        signInWithOAuth,
        signUp,
        signOut: async () => await supabaseSignOut(),
        refreshSession,
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