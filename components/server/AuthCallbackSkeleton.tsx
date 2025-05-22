import React from 'react';

interface AuthCallbackSkeletonProps {
  status?: string;
  error?: string | null;
  onRetry?: () => void;
}

/**
 * 인증 콜백 페이지에서 사용하는 스켈레톤/로딩 UI
 * 정적 UI 부분은 서버 컴포넌트로 구현하고 
 * 버튼 클릭 같은 인터랙션이 필요한 부분만 클라이언트 컴포넌트로 분리
 */
export default function AuthCallbackSkeleton({
  status = '처리 중입니다...',
  error = null,
  onRetry,
}: AuthCallbackSkeletonProps) {
  // 에러 표시
  if (error) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4 text-center">
        <h1 className="text-2xl font-bold mb-4">로그인 오류</h1>
        <p className="text-red-500 mb-6">{error}</p>
        {/* 클라이언트 컴포넌트로 분리 필요한 부분 */}
        {onRetry ? (
          <div id="retry-button-container" data-retry-handler="true" />
        ) : (
          <a
            href="/login"
            className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
          >
            로그인으로 돌아가기
          </a>
        )}
      </div>
    );
  }

  // 로딩 표시
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 text-center">
      <div className="animate-spin w-12 h-12 border-4 border-gray-200 border-t-blue-500 rounded-full mb-4"></div>
      <h1 className="text-xl font-medium mb-2">처리 중입니다</h1>
      <p className="text-gray-600">{status}</p>
    </div>
  );
} 