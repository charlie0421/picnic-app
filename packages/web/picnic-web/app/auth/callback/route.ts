import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const code = formData.get('code');
  const state = formData.get('state');

  // 단순히 클라이언트 페이지로 리다이렉션
  const redirectUrl = `/auth/callback/client?code=${encodeURIComponent(code as string)}&state=${encodeURIComponent(state as string)}`;
  
  return NextResponse.redirect(new URL(redirectUrl, request.url), 302);
} 