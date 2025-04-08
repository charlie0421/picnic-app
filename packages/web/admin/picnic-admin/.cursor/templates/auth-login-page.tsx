import React from 'react';
import { Metadata } from 'next';
import { LoginForm } from '@/components/features/auth/login-form';

export const metadata: Metadata = {
  title: '로그인',
  description: '관리자 로그인 페이지',
};

export default function LoginPage() {
  return (
    <div className='container flex h-screen w-screen flex-col items-center justify-center'>
      <div className='mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]'>
        <div className='flex flex-col space-y-2 text-center'>
          <h1 className='text-2xl font-semibold tracking-tight'>
            관리자 로그인
          </h1>
          <p className='text-sm text-muted-foreground'>
            이메일과 비밀번호를 입력하세요
          </p>
        </div>
        <LoginForm />
      </div>
    </div>
  );
}
