import React from 'react';
import { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: '페이지를 찾을 수 없습니다',
  description: '요청한 페이지를 찾을 수 없습니다',
};

export default function NotFoundPage() {
  return (
    <div className='flex h-screen flex-col items-center justify-center'>
      <h1 className='text-4xl font-bold'>404</h1>
      <p className='mt-4 text-lg text-muted-foreground'>
        요청한 페이지를 찾을 수 없습니다
      </p>
      <Link
        href='/'
        className='mt-4 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90'
      >
        홈으로 돌아가기
      </Link>
    </div>
  );
}
