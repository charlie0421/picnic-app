import React from 'react';
import { Metadata } from 'next';
import { RegisterForm } from '@/components/features/auth/register-form';

export const metadata: Metadata = {
  title: '회원가입',
  description: '관리자 회원가입 페이지',
};

export default function RegisterPage() {
  return (
    <div className='container flex h-screen w-screen flex-col items-center justify-center'>
      <div className='mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]'>
        <div className='flex flex-col space-y-2 text-center'>
          <h1 className='text-2xl font-semibold tracking-tight'>
            관리자 회원가입
          </h1>
          <p className='text-sm text-muted-foreground'>
            관리자 계정을 생성하세요
          </p>
        </div>
        <RegisterForm />
      </div>
    </div>
  );
}
