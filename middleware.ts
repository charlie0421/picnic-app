import type {NextRequest} from 'next/server';
import {NextResponse} from 'next/server';
import {DEFAULT_LANGUAGE, SUPPORTED_LANGUAGES} from './config/settings';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // applink.picnic.fan/vote/detail/ 경로를 vote/로 리다이렉트
  if (pathname.includes('/vote/detail/')) {
    const voteId = pathname.split('/').pop();
    console.log('voteId', voteId);
    return NextResponse.redirect(new URL(`/vote/${voteId}`, request.url));
  }

  // 정적 파일 경로는 건너뛰기
  if (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/static/') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // auth/callback 경로는 언어 경로 없이 직접 접근
  if (pathname.startsWith('/auth/callback')) {
    return NextResponse.next();
  }

  // 이미 언어가 포함된 경로인지 확인
  const pathnameHasLang = SUPPORTED_LANGUAGES.some(lang => pathname.startsWith(`/${lang}/`) || pathname === `/${lang}`);

  if (pathnameHasLang) {
    return NextResponse.next();
  }

  // 쿠키에서 현재 언어 확인
  const currentLang = request.cookies.get('NEXT_LOCALE')?.value;
  const preferredLang = SUPPORTED_LANGUAGES.includes(currentLang as any) ? currentLang : DEFAULT_LANGUAGE;

  // 기본 언어로 리다이렉트
  const newUrl = new URL(request.url);
  newUrl.pathname = `/${preferredLang}${pathname}`;
  return NextResponse.redirect(newUrl);
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
