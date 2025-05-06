'use client';

import React, { useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { ProfileImageContainer, DefaultAvatar } from '@/components/ui/ProfileImageContainer';
import { useRouter } from 'next/navigation';
import { supabase } from '@/utils/supabase-client';

const MyPage = () => {
  const { authState, signOut } = useAuth();
  const { user, loading } = authState;
  const router = useRouter();

  // 페이지 로드 시 인증 상태 강제 확인
  useEffect(() => {
    const checkAuthStatus = async () => {
      try {
        // 현재 세션 확인
        const { data } = await supabase.auth.getSession();
        
        // 세션이 있지만 사용자 정보가 없는 경우 auth.state.changed 이벤트 발생
        if (data.session && !user) {
          window.dispatchEvent(new Event('auth.state.changed'));
        }
      } catch (error) {
        console.error('세션 확인 중 오류:', error);
      }
    };
    
    if (!user && !loading) {
      // 로딩이 끝났으나 사용자 정보가 없으면 로그인 페이지로 이동
      router.push('/login');
    } else if (loading) {
      // 로딩 중이면 인증 상태 강제 확인
      checkAuthStatus();
    }
  }, [user, loading, router]);

  const handleSignOut = async () => {
    try {
      // 로그아웃 진행 전에 먼저 리디렉션 준비
      console.log('로그아웃 시작, 곧 홈으로 이동합니다');
      
      // 비동기 작업 전에 즉시 페이지 이동을 예약
      // 이렇게 하면 인증 상태 변경 이벤트가 라우터에 의한 리디렉션을 트리거하기 전에 
      // 브라우저가 루트 페이지로 이동하기 시작함
      const redirectTimer = setTimeout(() => {
        window.location.href = '/';
      }, 100);
      
      // signOut 함수 호출 (백그라운드에서 계속 진행됨)
      await signOut();
      
      // 추가적인 로그인 흔적 제거 (백그라운드에서 실행)
      try {
        // 모든 세션 쿠키 정리 (다시 한번)
        document.cookie.split(';').forEach(c => {
          const cookieName = c.trim().split('=')[0];
          if (cookieName) {
            document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
          }
        });
      } catch (e) {
        console.warn('추가 쿠키 정리 실패:', e);
      }
      
      // 이미 페이지 이동이 시작되었으므로 여기서는 추가 작업이 필요 없음
      
    } catch (error) {
      console.error('로그아웃 중 오류가 발생했습니다:', error);
      
      // 오류가 발생하더라도 즉시 홈으로 이동
      window.location.href = '/';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex justify-center items-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-[70vh] flex flex-col justify-center items-center p-4">
        <h1 className="text-2xl font-bold mb-6">로그인이 필요합니다</h1>
        <p className="text-gray-600 mb-8">마이페이지를 이용하기 위해서는 로그인이 필요합니다.</p>
        <Link
          href="/login"
          className="px-6 py-2 bg-primary-500 text-white rounded-md hover:bg-primary-600 transition-colors"
        >
          로그인하기
        </Link>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <div className="flex flex-col sm:flex-row items-start sm:items-center">
          <div className="mb-4 sm:mb-0 sm:mr-6">
            {user.avatarUrl ? (
              <ProfileImageContainer
                avatarUrl={user.avatarUrl}
                width={100}
                height={100}
                borderRadius={12}
              />
            ) : (
              <DefaultAvatar width={100} height={100} />
            )}
          </div>
          <div>
            <h1 className="text-2xl font-bold mb-2">{user.nickname || '사용자'}</h1>
            <p className="text-gray-600 mb-1">{user.email}</p>
            {user.birthDate && <p className="text-gray-700 mt-2">{user.birthDate}</p>}
            {user.isAdmin && (
              <div className="mt-2 bg-blue-100 text-blue-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded">
                관리자
              </div>
            )}
          </div>
        </div>

        <div className="mt-8 border-t border-gray-200 pt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h2 className="text-lg font-semibold mb-4">계정 관리</h2>
              <ul className="space-y-3">
                <li>
                  <Link href="/mypage/edit-profile" className="text-primary-600 hover:underline">
                    프로필 수정
                  </Link>
                </li>
                <li>
                  <Link href="/mypage/change-password" className="text-primary-600 hover:underline">
                    비밀번호 변경
                  </Link>
                </li>
                <li>
                  <button
                    onClick={handleSignOut}
                    className="text-red-600 hover:underline"
                  >
                    로그아웃
                  </button>
                </li>
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-semibold mb-4">활동 내역</h2>
              <ul className="space-y-3">
                <li>
                  <Link href="/mypage/votes" className="text-primary-600 hover:underline">
                    내 투표 보기
                  </Link>
                </li>
                <li>
                  <Link href="/mypage/posts" className="text-primary-600 hover:underline">
                    내 게시글 보기
                  </Link>
                </li>
                <li>
                  <Link href="/mypage/comments" className="text-primary-600 hover:underline">
                    내 댓글 보기
                  </Link>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-lg font-semibold mb-4">설정</h2>
        <ul className="space-y-3">
          <li>
            <Link href="/mypage/notifications" className="text-primary-600 hover:underline">
              알림 설정
            </Link>
          </li>
          <li>
            <Link href="/privacy" className="text-primary-600 hover:underline">
              개인정보 처리방침
            </Link>
          </li>
          <li>
            <Link href="/terms" className="text-primary-600 hover:underline">
              이용약관
            </Link>
          </li>
          <li>
            <Link href="/mypage/delete-account" className="text-red-600 hover:underline">
              회원탈퇴
            </Link>
          </li>
        </ul>
      </div>
    </div>
  );
};

export default MyPage; 