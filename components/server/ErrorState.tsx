import React from 'react';
import Link from 'next/link';

interface ErrorStateProps {
  message?: string;
  code?: string | number;
  retryLink?: string;
  retryLabel?: string;
}

/**
 * 서버 컴포넌트에서 사용할 오류 상태 표시 컴포넌트
 * error.js 또는 try/catch 블록과 함께 사용할 수 있습니다.
 */
export default function ErrorState({ 
  message = '오류가 발생했습니다.', 
  code = '500',
  retryLink,
  retryLabel = '다시 시도'
}: ErrorStateProps) {
  return (
    <div className="flex flex-col justify-center items-center min-h-[300px] p-4">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-red-500">{code}</h2>
        <p className="mt-2 text-gray-700">{message}</p>
        {retryLink && (
          <Link 
            href={retryLink}
            className="mt-4 inline-block px-4 py-2 bg-primary text-white rounded hover:bg-primary/80 transition-colors"
          >
            {retryLabel}
          </Link>
        )}
      </div>
    </div>
  );
} 