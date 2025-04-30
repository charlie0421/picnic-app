import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const code = formData.get('code');
  const state = formData.get('state');

  // GET 방식으로 리다이렉트하여 클라이언트에서 처리 가능하도록 전달
  const redirectUrl = `/auth/callback/client?code=${encodeURIComponent(code as string)}&state=${encodeURIComponent(state as string)}`;
  
  return NextResponse.redirect(new URL(redirectUrl, request.url), 302);
} 