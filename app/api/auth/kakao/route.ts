import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';
import { normalizeKakaoProfile } from '@/lib/supabase/social/kakao';
import { SocialAuthError } from '@/lib/supabase/social/types';

/**
 * Kakao 토큰 및 사용자 정보 처리 API
 * 
 * 이 API는 Kakao OAuth 콜백으로부터 받은 코드를 사용하여
 * 액세스 토큰을 획득하고 사용자 정보를 가져오는 역할을 합니다.
 */
export async function POST(request: NextRequest) {
  try {
    const { code, accessToken } = await request.json();
    
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
    
    // Kakao API 설정
    const clientId = process.env.NEXT_PUBLIC_KAKAO_CLIENT_ID;
    const clientSecret = process.env.KAKAO_CLIENT_SECRET;
    
    if (!clientId) {
      return NextResponse.json(
        { error: 'Kakao 클라이언트 ID가 설정되지 않았습니다.' },
        { status: 500 }
      );
    }
    
    let token = accessToken;
    
    // 코드가 있으면 액세스 토큰으로 교환
    if (code && !token) {
      const redirectUri = request.headers.get('referer')?.includes('callback')
        ? `${request.headers.get('origin')}/auth/callback/kakao`
        : `${request.headers.get('origin')}/api/auth/kakao`;
      
      const tokenResponse = await fetch('https://kauth.kakao.com/oauth/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
          grant_type: 'authorization_code',
          client_id: clientId,
          ...(clientSecret && { client_secret: clientSecret }),
          redirect_uri: redirectUri || '',
          code
        }).toString()
      });
      
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
      token = tokenData.access_token;
      
      if (!token) {
        return NextResponse.json(
          { error: 'Kakao 액세스 토큰을 획득하지 못했습니다.' },
          { status: 400 }
        );
      }
    }
    
    if (!token) {
      return NextResponse.json(
        { error: 'Kakao 액세스 토큰이 필요합니다.' },
        { status: 400 }
      );
    }
    
    // 사용자 정보 요청
    const userInfoResponse = await fetch('https://kapi.kakao.com/v2/user/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8'
      }
    });
    
    if (!userInfoResponse.ok) {
      return NextResponse.json(
        { 
          error: 'Kakao 사용자 정보 요청 실패', 
          details: await userInfoResponse.text() 
        },
        { status: 400 }
      );
    }
    
    const userInfo = await userInfoResponse.json();
    
    // 프로필 정보 정규화
    const normalizedProfile = normalizeKakaoProfile(userInfo);
    
    // Supabase에 사용자가 이미 존재하는지 확인
    if (normalizedProfile.email) {
      try {
        // listUsers에서 filter 옵션이 지원되지 않으므로 결과에서 직접 필터링
        const { data: users, error: userError } = await supabase.auth.admin.listUsers();
        
        if (userError) {
          throw userError;
        }
        
        // 이메일로 필터링하여 일치하는 사용자 찾기
        const matchedUser = users?.users.find(u => u.email === normalizedProfile.email);
        const user = matchedUser ? { user: matchedUser } : null;
        
        if (user?.user) {
          // 사용자가 존재하면 반환
          return NextResponse.json({
            success: true,
            profile: normalizedProfile,
            existingUser: true
          });
        }
      } catch (error) {
        console.error('Supabase 사용자 조회 오류:', error);
        // 오류가 발생해도 계속 진행 (새 사용자 생성 시도)
      }
    }
    
    // 새 사용자 정보 반환
    return NextResponse.json({
      success: true,
      profile: normalizedProfile,
      existingUser: false
    });
    
  } catch (error) {
    console.error('Kakao API 요청 처리 오류:', error);
    
    return NextResponse.json(
      { 
        error: error instanceof Error ? error.message : 'Kakao API 요청 처리 중 오류가 발생했습니다.' 
      },
      { status: 500 }
    );
  }
}

/**
 * Kakao 연결 해제 처리
 */
export async function DELETE(request: NextRequest) {
  try {
    const { accessToken } = await request.json();
    
    if (!accessToken) {
      return NextResponse.json(
        { error: 'Kakao 액세스 토큰이 필요합니다.' },
        { status: 400 }
      );
    }
    
    // Kakao 연결 해제 요청
    const unlinkResponse = await fetch('https://kapi.kakao.com/v1/user/unlink', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    if (!unlinkResponse.ok) {
      return NextResponse.json(
        { 
          error: 'Kakao 연결 해제 요청 실패', 
          details: await unlinkResponse.text() 
        },
        { status: 400 }
      );
    }
    
    const unlinkData = await unlinkResponse.json();
    
    return NextResponse.json({
      success: true,
      id: unlinkData.id
    });
    
  } catch (error) {
    console.error('Kakao 연결 해제 처리 오류:', error);
    
    return NextResponse.json(
      { 
        error: error instanceof Error ? error.message : 'Kakao 연결 해제 처리 중 오류가 발생했습니다.' 
      },
      { status: 500 }
    );
  }
}