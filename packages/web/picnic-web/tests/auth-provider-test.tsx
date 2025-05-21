'use client';

/**
 * 통합된 AuthProvider 테스트
 * 
 * 이 파일은 통합된 AuthProvider가 제대로 작동하는지 확인하기 위한 테스트입니다.
 * 개발 중에만 사용되며, 프로덕션에서는 사용되지 않습니다.
 */

import React, { useEffect, useState } from 'react';
import { useAuth } from '@/lib/supabase/auth-provider';

export default function AuthProviderTest() {
  const { isAuthenticated, isLoading, user, userProfile, error, signInWithOAuth } = useAuth();
  const [logs, setLogs] = useState<string[]>([]);

  const addLog = (message: string) => {
    setLogs(prev => [...prev, `[${new Date().toISOString()}] ${message}`]);
  };

  useEffect(() => {
    addLog(`인증 상태 확인: isAuthenticated=${isAuthenticated}, isLoading=${isLoading}`);
    if (user) {
      addLog(`사용자 정보: ID=${user.id}, 이메일=${user.email}`);
    } else {
      addLog('사용자 정보 없음');
    }
    
    if (userProfile) {
      addLog(`프로필 정보: 닉네임=${userProfile.nickname}, 아바타=${userProfile.avatarUrl ? '있음' : '없음'}`);
    } else {
      addLog('프로필 정보 없음');
    }

    if (error) {
      addLog(`오류: ${error}`);
    }
  }, [isAuthenticated, isLoading, user, userProfile, error]);

  const handleLogin = async (provider: 'google' | 'apple' | 'kakao' | 'wechat') => {
    addLog(`${provider} 로그인 시도...`);
    try {
      const result = await signInWithOAuth(provider);
      if (result.error) {
        addLog(`로그인 오류: ${result.error.message}`);
      } else {
        addLog(`${provider} 로그인 리디렉션 시작...`);
      }
    } catch (error) {
      addLog(`로그인 예외: ${error instanceof Error ? error.message : String(error)}`);
    }
  };

  return (
    <div className="p-4 max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">AuthProvider 테스트</h1>
      
      <div className="mb-4">
        <h2 className="text-xl font-semibold mb-2">상태</h2>
        <div className="grid grid-cols-2 gap-2">
          <div className="bg-gray-100 p-2 rounded">
            <span className="font-medium">인증 상태:</span> 
            {isLoading ? '로딩 중...' : isAuthenticated ? '로그인됨' : '로그아웃됨'}
          </div>
          <div className="bg-gray-100 p-2 rounded">
            <span className="font-medium">오류:</span> 
            {error || '없음'}
          </div>
        </div>
      </div>

      <div className="mb-4">
        <h2 className="text-xl font-semibold mb-2">사용자 정보</h2>
        {user ? (
          <div className="bg-blue-50 p-3 rounded">
            <p><span className="font-medium">ID:</span> {user.id}</p>
            <p><span className="font-medium">이메일:</span> {user.email}</p>
          </div>
        ) : (
          <div className="bg-gray-50 p-3 rounded">사용자 정보 없음</div>
        )}
      </div>

      <div className="mb-4">
        <h2 className="text-xl font-semibold mb-2">프로필 정보</h2>
        {userProfile ? (
          <div className="bg-green-50 p-3 rounded">
            <p><span className="font-medium">닉네임:</span> {userProfile.nickname || '(없음)'}</p>
            <p><span className="font-medium">아바타:</span> {userProfile.avatarUrl || '(없음)'}</p>
            <p><span className="font-medium">관리자:</span> {userProfile.isAdmin ? '예' : '아니오'}</p>
          </div>
        ) : (
          <div className="bg-gray-50 p-3 rounded">프로필 정보 없음</div>
        )}
      </div>

      <div className="mb-4">
        <h2 className="text-xl font-semibold mb-2">소셜 로그인 테스트</h2>
        <div className="grid grid-cols-2 gap-2">
          <button 
            onClick={() => handleLogin('google')} 
            className="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow"
          >
            Google 로그인
          </button>
          <button 
            onClick={() => handleLogin('apple')} 
            className="bg-black hover:bg-gray-900 text-white font-semibold py-2 px-4 border border-gray-400 rounded shadow"
          >
            Apple 로그인
          </button>
          <button 
            onClick={() => handleLogin('kakao')} 
            className="bg-yellow-400 hover:bg-yellow-500 text-gray-900 font-semibold py-2 px-4 border border-gray-400 rounded shadow"
          >
            Kakao 로그인
          </button>
          <button 
            onClick={() => handleLogin('wechat')} 
            className="bg-green-500 hover:bg-green-600 text-white font-semibold py-2 px-4 border border-gray-400 rounded shadow"
          >
            WeChat 로그인
          </button>
        </div>
      </div>

      <div className="mt-6">
        <h2 className="text-xl font-semibold mb-2">로그</h2>
        <div className="bg-black text-green-400 p-3 rounded h-64 overflow-y-auto font-mono text-sm">
          {logs.map((log, index) => (
            <div key={index}>{log}</div>
          ))}
        </div>
      </div>
    </div>
  );
} 