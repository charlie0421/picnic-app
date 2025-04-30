import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const code = formData.get('code');
  const state = formData.get('state');

  // 앱 정보를 포함한 리다이렉션 URL 생성
  const redirectUrl = `/auth/callback/client?code=${encodeURIComponent(code as string)}&state=${encodeURIComponent(state as string)}&client_id=io.iconcasting.picnic.app`;
  
  return NextResponse.redirect(new URL(redirectUrl, request.url), 302);
} 