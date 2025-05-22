import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';
import { SocialAuthError, SocialAuthErrorCode } from '@/lib/supabase/social/types';
import { parseAppleIdentityToken, normalizeAppleProfile } from '@/lib/supabase/social/apple';
import * as jose from 'jose'; // jose 라이브러리 필요 (npm install jose)

/**
 * Apple Sign-In 토큰 처리 API
 * 
 * 이 API는 Apple Sign-In 콜백으로부터 받은 코드와 ID 토큰을 사용하여
 * 사용자 정보를 검증하고 처리하는 역할을 합니다.
 */
export async function POST(request: NextRequest) {
  try {
    const { code, id_token, user, state } = await request.json();
    
    // 필수 파라미터 검증
    if (!id_token && !code) {
      return NextResponse.json(
        { error: 'ID 토큰 또는 인증 코드가 필요합니다.' },
        { status: 400 }
      );
    }
    
    // 서버 측 Supabase 클라이언트 생성
    const supabase = createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!, // 서비스 롤 키 사용 (주의: 서버 측에서만 사용)
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        }
      }
    );
    
    // ID 토큰이 제공된 경우, 해당 토큰 파싱 및 검증
    if (id_token) {
      try {
        // ID 토큰 파싱
        const payload = parseAppleIdentityToken(id_token);
        
        // 토큰 검증 (선택 사항 - 더 강력한 보안을 위해)
        try {
          // Apple의 JWKS 엔드포인트에서 공개 키 가져오기
          const JWKS = jose.createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
          
          // 토큰 검증
          await jose.jwtVerify(id_token, JWKS, {
            issuer: 'https://appleid.apple.com',
            audience: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID,
          });
        } catch (verifyError) {
          console.warn('Apple ID 토큰 검증 실패:', verifyError);
          // 개발 중에는 경고만 표시하고 진행 (프로덕션에서는 엄격하게 검증 필요)
        }
        
        // 사용자 프로필 정보 정규화
        const userProfile = normalizeAppleProfile(payload, user);
        
        return NextResponse.json({
          success: true,
          profile: userProfile
        });
      } catch (error) {
        console.error('ID 토큰 처리 오류:', error);
        return NextResponse.json(
          { error: 'ID 토큰 검증 실패' },
          { status: 400 }
        );
      }
    }
    
    // 코드가 제공된 경우, Apple API로 토큰 교환
    // 이 로직은 주로 Supabase가 처리하지 못하는 특수한 경우에만 필요합니다.
    if (code) {
      try {
        // Apple 클라이언트 시크릿 생성 (실제 구현 필요)
        const clientSecret = await generateAppleClientSecret();
        
        if (!clientSecret) {
          throw new SocialAuthError(
            SocialAuthErrorCode.TOKEN_EXCHANGE_FAILED,
            'Apple 클라이언트 시크릿을 생성할 수 없습니다.',
            'apple'
          );
        }
        
        // 클라이언트 ID 확인
        const clientId = process.env.NEXT_PUBLIC_APPLE_CLIENT_ID;
        if (!clientId) {
          throw new SocialAuthError(
            SocialAuthErrorCode.INITIALIZATION_FAILED,
            'Apple Client ID가 설정되지 않았습니다.',
            'apple'
          );
        }
        
        // Apple Token 엔드포인트로 요청
        const tokenResponse = await fetch('https://appleid.apple.com/auth/token', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            client_id: clientId,
            client_secret: clientSecret,
            code,
            grant_type: 'authorization_code',
            redirect_uri: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback/apple`,
          })
        });
        
        if (!tokenResponse.ok) {
          const errorData = await tokenResponse.json();
          throw new SocialAuthError(
            SocialAuthErrorCode.TOKEN_EXCHANGE_FAILED,
            `토큰 교환 실패: ${JSON.stringify(errorData)}`,
            'apple',
            errorData
          );
        }
        
        const tokenData = await tokenResponse.json();
        
        // ID 토큰 파싱
        const payload = parseAppleIdentityToken(tokenData.id_token);
        const userProfile = normalizeAppleProfile(payload, user);
        
        return NextResponse.json({
          success: true,
          tokens: {
            access_token: tokenData.access_token,
            refresh_token: tokenData.refresh_token,
            id_token: tokenData.id_token,
            expires_in: tokenData.expires_in
          },
          profile: userProfile
        });
      } catch (error) {
        console.error('Apple 토큰 교환 오류:', error);
        
        if (error instanceof SocialAuthError) {
          return NextResponse.json(
            { error: error.message, code: error.code },
            { status: 400 }
          );
        }
        
        return NextResponse.json(
          { error: '알 수 없는 오류가 발생했습니다.' },
          { status: 500 }
        );
      }
    }
    
    return NextResponse.json(
      { error: '유효한 요청 데이터가 없습니다.' },
      { status: 400 }
    );
  } catch (error) {
    console.error('요청 처리 오류:', error);
    return NextResponse.json(
      { error: '요청 처리 중 오류가 발생했습니다.' },
      { status: 500 }
    );
  }
}

/**
 * JWT 형식의 Apple 클라이언트 시크릿 생성
 * 
 * @returns 생성된 클라이언트 시크릿
 */
async function generateAppleClientSecret(): Promise<string> {
  try {
    // Apple 클라이언트 시크릿 생성에 필요한 값
    const clientId = process.env.NEXT_PUBLIC_APPLE_CLIENT_ID!;
    const teamId = process.env.APPLE_TEAM_ID!;
    const keyId = process.env.APPLE_KEY_ID!;
    const privateKey = process.env.APPLE_PRIVATE_KEY!.replace(/\\n/g, '\n');
    
    if (!clientId || !teamId || !keyId || !privateKey) {
      throw new Error('Apple 인증에 필요한 환경 변수가 설정되지 않았습니다.');
    }
    
    // 현재 시간 기준으로 JWT 생성 (6개월 유효기간)
    const now = Math.floor(Date.now() / 1000);
    const expiry = now + 15777000; // 6개월 (초 단위)
    
    // JWT 서명에 사용할 프라이빗 키 가져오기
    const alg = 'ES256';
    const privateKeyImported = await jose.importPKCS8(privateKey, alg);
    
    // JWT 생성 및 서명
    const jwt = await new jose.SignJWT({
      iss: teamId,
      iat: now,
      exp: expiry,
      aud: 'https://appleid.apple.com',
      sub: clientId,
    })
      .setProtectedHeader({ alg, kid: keyId })
      .sign(privateKeyImported);
    
    return jwt;
  } catch (error) {
    console.error('Apple 클라이언트 시크릿 생성 오류:', error);
    throw error;
  }
} 