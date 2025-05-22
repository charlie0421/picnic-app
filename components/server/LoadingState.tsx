import React from 'react';

interface LoadingStateProps {
  message?: string;
}

/**
 * 서버 컴포넌트에서 사용할 로딩 상태 표시 컴포넌트
 * Suspense와 함께 사용하면 로딩 중에 이 컴포넌트가 표시됩니다.
 */
export default function LoadingState({ message = '로딩 중...' }: LoadingStateProps) {
  return (
    <div className="flex justify-center items-center min-h-[300px]">
      <div className="text-center">
        <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
        <p className="mt-4 text-gray-600">{message}</p>
      </div>
    </div>
  );
} 