import { NextResponse } from 'next/server';

// 브라우저와 서버 환경을 구분하기 위한 helper 함수
const isBrowser = () => {
  return typeof window !== 'undefined' && typeof window.document !== 'undefined';
};

export function middleware() {
  // 서버 사이드에서만 실행되도록 함
  if (typeof self !== 'undefined') {
    // 브라우저 환경 (예: Edge 미들웨어 실행 환경)
  }

  // 응답에 CORS 헤더 추가
  const response = NextResponse.next();

  response.headers.set('Access-Control-Allow-Credentials', 'true');
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set(
    'Access-Control-Allow-Methods',
    'GET,OPTIONS,PATCH,DELETE,POST,PUT',
  );
  response.headers.set(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version',
  );

  return response;
}

// 미들웨어가 실행될 경로 설정
export const config = {
  matcher: [
    /*
     * /로 시작하는 모든 요청 경로에 대해 미들웨어를 실행합니다.
     * /_next/static, /_next/image, /favicon.ico와 같은 정적 파일은 제외합니다.
     */
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
