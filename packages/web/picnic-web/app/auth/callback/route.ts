import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const code = formData.get('code');
  const state = formData.get('state');

  // Supabase 콜백 URL로 리다이렉션
  const redirectUrl = `https://xtijtefcycoeqludlngc.supabase.co/auth/v1/callback?code=${encodeURIComponent(code as string)}&state=${encodeURIComponent(state as string)}`;
  
  return NextResponse.redirect(new URL(redirectUrl), 302);
} 