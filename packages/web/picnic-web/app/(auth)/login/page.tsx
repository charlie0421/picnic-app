'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '../../../contexts/AuthContext';
import SocialLogin from '../../../components/SocialLogin';
import { useLanguageStore } from '@/stores/languageStore';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { authState, signIn } = useAuth();
  const router = useRouter();
  const { t } = useLanguageStore();

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
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h1 className="text-2xl font-bold text-center mb-6">{t('auth_login_title')}</h1>
        </div>
        <form onSubmit={handleSubmit} className="mt-8 space-y-6">
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email" className="block text-gray-700 font-medium mb-2">
                {t('auth_login_email')}
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
                placeholder={t('auth_login_email_placeholder')}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="password" className="block text-gray-700 font-medium mb-2">
                {t('auth_login_password')}
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
                placeholder={t('auth_login_password_placeholder')}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              className="w-full bg-primary text-white py-2 px-4 rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
              disabled={authState.loading}
            >
              {authState.loading ? '로그인 중...' : t('auth_login_submit')}
            </button>
          </div>
        </form>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-300"></div>
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-gray-50 text-gray-500 uppercase">
              {t('auth_login_or')}
            </span>
          </div>
        </div>

        <SocialLogin className="mt-6" />
        
        <div className="text-center mt-4">
          <Link href="/auth/forgot-password" className="text-primary text-sm hover:underline">
            {t('auth_login_forgot_password')}
          </Link>
        </div>
        
        <div className="text-center mt-6 border-t border-gray-200 pt-4">
          <p className="text-gray-600 mb-4">{t('auth_login_no_account')}</p>
          <Link
            href="/auth/signup"
            className="text-primary font-medium hover:underline"
          >
            {t('auth_signup_title')}
          </Link>
        </div>
      </div>
    </div>
  );
};

export default LoginPage; 