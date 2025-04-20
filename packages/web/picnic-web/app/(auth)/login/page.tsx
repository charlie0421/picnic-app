'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '../../../contexts/AuthContext';
import SocialLogin from '../../../components/SocialLogin';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { authState, signIn } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }

    try {
      await signIn(email, password);
      // 에러가 없다면 홈으로 이동
      if (!authState.error) {
        router.push('/');
      } else {
        setError(authState.error);
      }
    } catch (error: any) {
      setError(error.message || '로그인 중 오류가 발생했습니다.');
    }
  };

  return (
    <div className="min-h-[80vh] flex items-center justify-center p-4">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6">로그인</h1>
        
        {error && (
          <div className="bg-red-100 text-red-700 p-3 rounded-md mb-4">
            {error}
          </div>
        )}
        
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="email" className="block text-gray-700 font-medium mb-2">
              이메일
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500"
              required
            />
          </div>
          
          <div className="mb-6">
            <label htmlFor="password" className="block text-gray-700 font-medium mb-2">
              비밀번호
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500"
              required
            />
          </div>
          
          <button
            type="submit"
            className="w-full bg-primary text-white py-2 px-4 rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
            disabled={authState.loading}
          >
            {authState.loading ? '로그인 중...' : '로그인'}
          </button>
        </form>
        
        <div className="mt-6 flex items-center justify-between">
          <span className="border-b w-1/4 md:w-1/3"></span>
          <span className="text-xs text-gray-500 uppercase">또는</span>
          <span className="border-b w-1/4 md:w-1/3"></span>
        </div>
        
        <SocialLogin className="mt-6" />
        
        <div className="text-center mt-4">
          <Link href="/auth/forgot-password" className="text-primary text-sm hover:underline">
            비밀번호를 잊으셨나요?
          </Link>
        </div>
        
        <div className="text-center mt-6 border-t border-gray-200 pt-4">
          <p className="text-gray-600 mb-4">계정이 없으신가요?</p>
          <Link
            href="/auth/signup"
            className="text-primary font-medium hover:underline"
          >
            회원가입
          </Link>
        </div>
      </div>
    </div>
  );
};

export default LoginPage; 