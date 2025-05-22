import React, { ReactNode, Suspense } from 'react';
import { ErrorCode, AppError, handleError } from '@/lib/supabase/error';
import ErrorState from './ErrorState';

interface AsyncBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  errorFallback?: (error: AppError) => ReactNode;
}

/**
 * 서버 컴포넌트에서 사용하는 비동기 에러 처리 컴포넌트
 * 
 * 비동기 작업을 수행하는 서버 컴포넌트를 try/catch로 감싸고
 * Suspense를 통한 로딩 상태와 에러 상태를 처리합니다.
 * 
 * @example
 * // 사용 예시:
 * async function DataComponent() {
 *   const data = await fetchData();
 *   return <div>{data.title}</div>;
 * }
 * 
 * export default function Page() {
 *   return (
 *     <AsyncBoundary 
 *       fallback={<div>로딩 중...</div>}
 *       errorFallback={(error) => (
 *         <ErrorState 
 *           message={error.toFriendlyMessage()} 
 *           code={error.status || 500} 
 *           retryLink="/some-path" 
 *         />
 *       )}
 *     >
 *       <DataComponent />
 *     </AsyncBoundary>
 *   );
 * }
 */
export default async function AsyncBoundary({ 
  children, 
  fallback = <div className="p-4 flex justify-center items-center">
    <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full"></div>
  </div>,
  errorFallback 
}: AsyncBoundaryProps) {
  try {
    return (
      <Suspense fallback={fallback}>
        {children}
      </Suspense>
    );
  } catch (error) {
    console.error('AsyncBoundary 에러:', error);
    
    // 에러를 애플리케이션 표준 에러로 변환
    const appError = error instanceof AppError ? error : handleError(error);
    
    // 사용자 정의 에러 fallback이 있으면 사용
    if (errorFallback) {
      return errorFallback(appError);
    }
    
    // 기본 에러 상태 컴포넌트 표시
    return (
      <ErrorState 
        message={appError.toFriendlyMessage()}
        code={appError.status || 500}
        retryLink="/"
      />
    );
  }
} 