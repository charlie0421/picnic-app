import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';
import { SocialAuthError, SocialAuthErrorCode } from '@/lib/supabase/social/types';
import { normalizeWeChatProfile } from '@/lib/supabase/social/wechat';

/**
 * WeChat 토큰 및 사용자 정보 처리 API
 * 
 * 이 API는 WeChat OAuth 콜백으로부터 받은 코드를 사용하여
 * 액세스 토큰을 획득하고 사용자 정보를 가져오는 역할을 합니다.
 */
export async function POST(request: NextRequest) {
  try {
    const { code, state } = await request.json();
    
    // 필수 파라미터 검증
    if (!code) {
      return NextResponse.json(
        { error: 'OAuth 코드가 필요합니다.' },
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
    
    // WeChat API 설정
    const appId = process.env.NEXT_PUBLIC_WECHAT_APP_ID;
    const appSecret = process.env.WECHAT_APP_SECRET;
    
    if (!appId || !appSecret) {
      return NextResponse.json(
        { 
          error: 'WeChat 앱 ID 또는 시크릿이 설정되지 않았습니다.' 
        },
        { status: 500 }
      );
    }
    
    // 1. 코드로 액세스 토큰 획득
    const tokenResponse = await fetch(
      `https://api.weixin.qq.com/sns/oauth2/access_token?appid=${appId}&secret=${appSecret}&code=${code}&grant_type=authorization_code`,
      { method: 'GET' }
    );
    
    if (!tokenResponse.ok) {
      return NextResponse.json(
        { 
          error: '액세스 토큰 요청 실패', 
          details: await tokenResponse.text() 
        },
        { status: 400 }
      );
    }
    
    const tokenData = await tokenResponse.json();
    
    if (tokenData.errcode) {
      return NextResponse.json(
        { 
          error: `WeChat API 오류: ${tokenData.errmsg}`, 
          code: tokenData.errcode 
        },
        { status: 400 }
      );
    }
    
    const accessToken = tokenData.access_token;
    const openId = tokenData.openid;
    const refreshToken = tokenData.refresh_token;
    const expiresIn = tokenData.expires_in;
    
    // 2. 액세스 토큰으로 사용자 정보 가져오기
    const userInfoResponse = await fetch(
      `https://api.weixin.qq.com/sns/userinfo?access_token=${accessToken}&openid=${openId}&lang=zh_CN`,
      { method: 'GET' }
    );
    
    if (!userInfoResponse.ok) {
      return NextResponse.json(
        { 
          error: '사용자 정보 요청 실패', 
          details: await userInfoResponse.text() 
        },
        { status: 400 }
      );
    }
    
    const userInfo = await userInfoResponse.json();
    
    if (userInfo.errcode) {
      return NextResponse.json(
        { 
          error: `WeChat API 오류: ${userInfo.errmsg}`, 
          code: userInfo.errcode 
        },
        { status: 400 }
      );
    }
    
    // 프로필 정보 정규화
    const normalizedProfile = normalizeWeChatProfile(userInfo);
    
    // 3. JWT 토큰 생성 (Supabase 인증용)
    // 참고: 실제 프로덕션 환경에서는 더 안전한 방식의 JWT 생성 및 서명 필요
    const idToken = await generateJwtToken({
      sub: normalizedProfile.id,
      name: normalizedProfile.name,
      picture: normalizedProfile.avatar,
      provider: 'wechat'
    });
    
    // 4. Supabase에 사용자 데이터 저장 (선택 사항)
    try {
      // Supabase 사용자가 이미 존재하는지 확인 (openId 기준)
      const { data: existingUsers } = await supabase
        .from('user_profiles')
        .select('id')
        .eq('provider', 'wechat')
        .eq('provider_id', normalizedProfile.id);
      
      if (existingUsers && existingUsers.length > 0) {
        // 기존 사용자가 있으면 프로필 업데이트
        const userId = existingUsers[0].id;
        
        await supabase.from('user_profiles').update({
          display_name: normalizedProfile.name,
          avatar_url: normalizedProfile.avatar,
          updated_at: new Date().toISOString()
        }).eq('id', userId);
        
        normalizedProfile.userId = userId;
      }
    } catch (error) {
      console.warn('Supabase 사용자 업데이트 실패:', error);
      // 사용자 업데이트 실패해도 계속 진행
    }
    
    return NextResponse.json({
      success: true,
      tokens: {
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: expiresIn,
        id_token: idToken
      },
      profile: normalizedProfile
    });
  } catch (error) {
    console.error('WeChat API 요청 처리 오류:', error);
    
    return NextResponse.json(
      { 
        error: error instanceof Error ? error.message : '요청 처리 중 오류가 발생했습니다.' 
      },
      { status: 500 }
    );
  }
}

/**
 * WeChat 토큰 갱신 API
 */
export async function PUT(request: NextRequest) {
  try {
    const { refresh_token } = await request.json();
    
    if (!refresh_token) {
      return NextResponse.json(
        { error: '리프레시 토큰이 필요합니다.' },
        { status: 400 }
      );
    }
    
    // WeChat API 설정
    const appId = process.env.NEXT_PUBLIC_WECHAT_APP_ID;
    
    if (!appId) {
      return NextResponse.json(
        { error: 'WeChat 앱 ID가 설정되지 않았습니다.' },
        { status: 500 }
      );
    }
    
    // 토큰 갱신 요청
    const refreshResponse = await fetch(
      `https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=${appId}&grant_type=refresh_token&refresh_token=${refresh_token}`,
      { method: 'GET' }
    );
    
    if (!refreshResponse.ok) {
      return NextResponse.json(
        { 
          error: '토큰 갱신 요청 실패',
          details: await refreshResponse.text()
        },
        { status: 400 }
      );
    }
    
    const refreshData = await refreshResponse.json();
    
    if (refreshData.errcode) {
      return NextResponse.json(
        { 
          error: `WeChat API 오류: ${refreshData.errmsg}`,
          code: refreshData.errcode
        },
        { status: 400 }
      );
    }
    
    return NextResponse.json({
      success: true,
      tokens: {
        access_token: refreshData.access_token,
        refresh_token: refreshData.refresh_token,
        expires_in: refreshData.expires_in,
        openid: refreshData.openid
      }
    });
  } catch (error) {
    console.error('WeChat 토큰 갱신 오류:', error);
    
    return NextResponse.json(
      { error: '토큰 갱신 중 오류가 발생했습니다.' },
      { status: 500 }
    );
  }
}

/**
 * 간단한 JWT 토큰 생성 함수
 * 참고: 프로덕션에서는 jose 라이브러리 등을 사용하여 
 * 더 안전한 토큰 생성 및 서명 방식을 사용해야 합니다.
 */
async function generateJwtToken(payload: any): Promise<string> {
  // 실제 구현에서는 jose 라이브러리와 같은 도구를 사용하여
  // 적절한 서명 및 검증 로직을 구현해야 합니다.
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };
  
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = 3600; // 1시간
  
  const tokenPayload = {
    ...payload,
    iat: now,
    exp: now + expiresIn,
    iss: 'picnic-web',
    aud: 'picnic-web'
  };
  
  // 간단한 인코딩 (프로덕션에는 적합하지 않음)
  const base64UrlEncode = (obj: any) => 
    Buffer.from(JSON.stringify(obj)).toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  
  const headerEncoded = base64UrlEncode(header);
  const payloadEncoded = base64UrlEncode(tokenPayload);
  
  // 간단한 서명 (프로덕션에는 적합하지 않음)
  // 실제 사용 시에는 HMAC 또는 RSA 서명 사용
  const signature = 'dummy_signature';
  
  return `${headerEncoded}.${payloadEncoded}.${signature}`;
} 