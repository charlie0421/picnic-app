'use client';

import React from 'react';
import { useRouter } from 'next/navigation';

interface RetryButtonProps {
  redirectPath?: string;
}

/**
 * 로그인 오류 시 재시도 버튼 컴포넌트
 * 
 * 클라이언트 이벤트 핸들링이 필요하기 때문에 클라이언트 컴포넌트로 구현
 */
export default function RetryButton({ redirectPath = '/login' }: RetryButtonProps) {
  const router = useRouter();

  const handleClick = () => {
    router.push(redirectPath);
  };

  return (
    <button
      onClick={handleClick}
      className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
    >
      로그인으로 돌아가기
    </button>
  );
} 