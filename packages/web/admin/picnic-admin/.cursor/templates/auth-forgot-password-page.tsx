import React from 'react';
import { Metadata } from 'next';
import { ForgotPasswordForm } from '@/components/features/auth/forgot-password-form';

export const metadata: Metadata = {
  title: '비밀번호 재설정',
  description: '비밀번호 재설정 페이지',
};

export default function ForgotPasswordPage() {
  return (
    <div className='container flex h-screen w-screen flex-col items-center justify-center'>
      <div className='mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]'>
        <div className='flex flex-col space-y-2 text-center'>
          <h1 className='text-2xl font-semibold tracking-tight'>
            비밀번호 재설정
          </h1>
          <p className='text-sm text-muted-foreground'>
            이메일을 입력하시면 비밀번호 재설정 링크를 보내드립니다
          </p>
        </div>
        <ForgotPasswordForm />
      </div>
    </div>
  );
}
