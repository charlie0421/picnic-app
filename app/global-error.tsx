// app/global-error.tsx
'use client';

import { useEffect } from 'react';

/**
 * 글로벌 에러 처리 컴포넌트
 * 
 * Next.js 15.3.1에서 개선된 에러 디버깅을 위한 컴포넌트입니다.
 * 애플리케이션 전체에서 발생하는 예기치 않은 에러를 처리합니다.
 */
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // 에러 로깅 - 프로덕션 환경에서는 Sentry 등의 서비스로 전송
    console.error('애플리케이션 전역 에러:', error);
  }, [error]);

  return (
    <html lang="ko">
      <body>
        <div className="flex min-h-screen flex-col items-center justify-center p-4 text-center">
          <div className="max-w-md">
            <h1 className="text-3xl font-bold mb-4">오류가 발생했습니다</h1>
            <p className="text-gray-600 mb-6">
              애플리케이션에 예기치 않은 오류가 발생했습니다. 이 문제가 계속되면 관리자에게 문의하세요.
            </p>
            {error.digest && (
              <p className="text-xs text-gray-500 mb-6">
                오류 코드: {error.digest}
              </p>
            )}
            <button
              onClick={reset}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
            >
              다시 시도
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}