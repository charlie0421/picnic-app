'use client';

import React from 'react';
import Link from 'next/link';
import {useAuth} from '@/contexts/AuthContext';
import {DefaultAvatar, ProfileImageContainer} from '@/components/ui/ProfileImageContainer';
import {useLanguageStore} from '@/stores/languageStore';

const MyPage = () => {
  const { authState, signOut } = useAuth();
  const { user, loading } = authState;
  const { t } = useLanguageStore();

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

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="bg-white rounded-lg shadow-md p-6 mb-8 relative">
        <div className="flex flex-col sm:flex-row items-start sm:items-center">
          <div className="mb-4 sm:mb-0 sm:mr-6">
            {user?.avatarUrl ? (
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
            <h1 className="text-2xl font-bold mb-2">{user?.nickname || '사용자'}</h1>
            <p className="text-gray-600 mb-1">{user?.email || '로그인 후 이메일이 표시됩니다'}</p>
            {user?.birthDate && <p className="text-gray-700 mt-2">{user?.birthDate}</p>}
            {user?.isAdmin && (
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
                {user ? (
                  <>
                    <li>
                      <Link href="/mypage/edit-profile" className="text-primary-600 hover:underline">
                        프로필 수정
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
                  </>
                ) : (
                  <li>
                    <Link href="/login" className="text-primary-600 hover:underline">
                      로그인하기
                    </Link>
                  </li>
                )}
              </ul>
            </div>

            <div>
              <h2 className="text-lg font-semibold mb-4">활동 내역</h2>
              <ul className="space-y-3">
                {user ? (
                  <>
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
                  </>
                ) : (
                  <li className="text-gray-500">
                    로그인 후 이용 가능한 서비스입니다
                  </li>
                )}
              </ul>
            </div>
          </div>
        </div>

        {!user && (
          <div className="absolute inset-0 backdrop-blur-md flex items-center justify-center rounded-lg">
            <div className="text-center bg-white/90 p-8 rounded-lg shadow-lg max-w-md mx-auto">
              <p className="text-gray-600 mb-6">프로필 정보를 보시려면 로그인해주세요.</p>
              <Link
                href="/login"
                className="inline-block bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition-colors"
              >
                로그인하기
              </Link>
            </div>
          </div>
        )}
      </div>

      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900">서비스 정보</h2>
        <ul className="space-y-3">
          <li>
            <Link href="/notice" className="text-primary-600 hover:underline">
              {t('label_mypage_notice')}
            </Link>
          </li>
          <li>
            <Link href="/faq" className="text-primary-600 hover:underline">
              {t('label_mypage_faq')}
            </Link>
          </li>
          <li>
            <Link href="/privacy" className="text-primary-600 hover:underline">
              {t('label_mypage_privacy_policy')}
            </Link>
          </li>
          <li>
            <Link href="/terms" className="text-primary-600 hover:underline">
              {t('label_mypage_terms_of_use')}
            </Link>
          </li>
          {user && (
            <li>
              <Link href="/mypage/delete-account" className="text-red-600 hover:underline">
                {t('label_mypage_withdrawal')}
              </Link>
            </li>
          )}
        </ul>
      </div>
    </div>
  );
};

export default MyPage;
