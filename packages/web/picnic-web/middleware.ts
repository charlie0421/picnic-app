import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { DEFAULT_LANGUAGE, SUPPORTED_LANGUAGES } from './config/settings';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // API 경로는 건너뛰기
  if (pathname.startsWith('/api/')) {
    return NextResponse.next();
  }

  // 정적 파일 경로는 건너뛰기
  if (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/static/') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // 이미 언어가 포함된 경로인지 확인
  const pathnameHasLang = SUPPORTED_LANGUAGES.some(lang => pathname.startsWith(`/${lang}/`) || pathname === `/${lang}`);

  if (pathnameHasLang) {
    return NextResponse.next();
  }

  // 기본 언어로 리다이렉트
  const newUrl = new URL(request.url);
  newUrl.pathname = `/${DEFAULT_LANGUAGE}${pathname}`;
  return NextResponse.redirect(newUrl);
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}; 