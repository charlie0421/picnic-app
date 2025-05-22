import React from 'react';

interface LoadingStateProps {
  message?: string;
  size?: 'small' | 'medium' | 'large';
  fullPage?: boolean;
}

/**
 * 서버 컴포넌트에서 데이터 로딩 중 표시할 컴포넌트
 * 
 * Next.js의 Suspense 또는 loading.tsx 파일과 함께 사용할 수 있습니다.
 * 
 * @example
 * // app/[lang]/(main)/vote/[id]/loading.tsx
 * import { LoadingState } from '@/components/server';
 * 
 * export default function VoteLoading() {
 *   return <LoadingState message="투표 데이터를 불러오는 중입니다..." />;
 * }
 */
export default function LoadingState({ 
  message = '로딩 중...',
  size = 'medium',
  fullPage = false,
}: LoadingStateProps) {
  // 크기에 따른 스피너 크기 설정
  const spinnerSize = {
    small: 'h-6 w-6 border-2',
    medium: 'h-10 w-10 border-4',
    large: 'h-16 w-16 border-4',
  }[size];
  
  // 컨테이너 크기 설정
  const containerClass = fullPage 
    ? 'flex flex-col justify-center items-center min-h-[70vh]'
    : 'flex flex-col justify-center items-center py-8';
  
  return (
    <div className={containerClass}>
      <div className={`animate-spin ${spinnerSize} border-primary border-t-transparent rounded-full`}></div>
      {message && (
        <p className="mt-4 text-gray-600">{message}</p>
      )}
    </div>
  );
} 