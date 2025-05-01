import { NextRequest, NextResponse } from 'next/server';
import { generatePKCE } from './pkce';

export const config = {
  runtime: 'edge'
};

export default async function handler(req: NextRequest) {
  if (req.method !== 'GET') {
    return new NextResponse('Method not allowed', { status: 405 });
  }

  try {
    // PKCE 생성
    const { codeVerifier, codeChallenge } = await generatePKCE();
    
    // state 생성
    const state = {
      redirect_url: req.nextUrl.searchParams.get('redirect_url') || '/',
      nonce: crypto.randomUUID(),
      code_verifier: codeVerifier,
      flow_state: crypto.randomUUID(),
      provider: 'apple',
      timestamp: Date.now()
    };

    // Apple OAuth URL 생성
    const clientId = 'io.iconcasting.picnic.app';
    const redirectUri = 'https://api.picnic.fan/auth/callback';
    const scope = 'name email';

    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: scope,
      response_mode: 'form_post',
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
      state: btoa(JSON.stringify(state))
    });

    const appleAuthUrl = `https://appleid.apple.com/auth/authorize?${params.toString()}`;

    // 쿠키 설정과 함께 리다이렉션
    const response = NextResponse.redirect(appleAuthUrl);
    
    // code_verifier 쿠키 설정
    response.cookies.set('sb-xtijtefcycoeqludlngc-auth-token-code-verifier', codeVerifier, {
      path: '/',
      secure: true,
      sameSite: 'lax',
      httpOnly: true
    });

    // flow_state 쿠키 설정
    response.cookies.set('sb-xtijtefcycoeqludlngc-auth-token-flow-state', state.flow_state, {
      path: '/',
      secure: true,
      sameSite: 'lax',
      httpOnly: true
    });

    return response;
  } catch (error) {
    console.error('OAuth 초기화 오류:', error);
    return NextResponse.redirect('/?error=oauth_init_error');
  }
} 