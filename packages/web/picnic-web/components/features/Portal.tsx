'use client';

import React, { useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useParams, usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigation } from '@/contexts/NavigationContext';
import { ProfileImageContainer, DefaultAvatar } from '@/components/ui/ProfileImageContainer';
import PortalMenuItem from '@/components/features/PortalMenuItem';
import { PortalType } from '@/utils/enums';

// 환경 설정 확인 (개발 환경인지)
const isDev = process.env.NODE_ENV !== 'production';

interface PortalProps {
  children: React.ReactNode;
}

const Portal: React.FC<PortalProps> = ({ children }) => {
  const { authState } = useAuth();
  const { navigationState, setCurrentPortalType } = useNavigation();
  const pathname = usePathname();

  // 경로에 따라 현재 포탈 타입 설정
  useEffect(() => {
    if (pathname.startsWith('/vote')) {
      setCurrentPortalType(PortalType.VOTE);
    } else if (pathname.startsWith('/community')) {
      setCurrentPortalType(PortalType.COMMUNITY);
    } else if (pathname.startsWith('/pic')) {
      setCurrentPortalType(PortalType.PIC);
    } else if (pathname.startsWith('/novel')) {
      setCurrentPortalType(PortalType.NOVEL);
    } else if (pathname.startsWith('/mypage')) {
      setCurrentPortalType(PortalType.MYPAGE);
    } else if (pathname.startsWith('/media')) {
      setCurrentPortalType(PortalType.MEDIA);
    } else if (pathname.startsWith('/shop')) {
      setCurrentPortalType(PortalType.SHOP);
    }
  }, [pathname, setCurrentPortalType]);

  return (
    <div className="bg-gradient-to-b from-blue-50 to-white min-h-screen">
      <div className="max-w-6xl mx-auto bg-white shadow-md min-h-screen">
        <header className="border-b border-gray-200 bg-white">
          <div className="container mx-auto flex items-center px-4 py-2">
            <div className="flex-1 overflow-x-auto py-1 scrollbar-hide">
              <div className="flex items-center justify-between w-full">
                <div className="flex items-center space-x-1">
                  <div className="flex items-center space-x-1">
                    <Image src="/images/logo.png" alt="logo" width={40} height={40} priority />
                  </div>
                  {/* 개발 환경 표시 */}
                  {/* {isDev && <div className="text-xs text-gray-400 mr-2">개발</div>} */}

                  {/* 포탈 메뉴 아이템들 - 하단 메뉴로 이동하고 여기는 간소화 */}
                  <PortalMenuItem portalType={PortalType.VOTE} />
                  <PortalMenuItem portalType={PortalType.COMMUNITY} />
                  <PortalMenuItem portalType={PortalType.PIC} />
                  <PortalMenuItem portalType={PortalType.NOVEL} />

                  {/* 관리자만 볼 수 있는 메뉴 */}
                  {authState.isAuthenticated && authState.user?.isAdmin && (
                    <>
                      <PortalMenuItem portalType={PortalType.PIC} />
                      <PortalMenuItem portalType={PortalType.NOVEL} />
                    </>
                  )}
                </div>

                {authState.isAuthenticated ? (
                  <Link href="/mypage">
                    {authState.user?.avatarUrl ? (
                      <ProfileImageContainer
                        avatarUrl={authState.user.avatarUrl}
                        width={36}
                        height={36}
                        borderRadius={8}
                      />
                    ) : (
                      <DefaultAvatar width={36} height={36} />
                    )}
                  </Link>
                ) : (
                  <Link href="/auth/login">
                    <div className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors">
                      로그인
                    </div>
                  </Link>
                )}
              </div>
            </div>
          </div>
        </header>
        <main className="container mx-auto px-4 py-0">
          <div className="flex flex-col">
            <div className="w-full">
              {/* 메인 콘텐츠 */}
              <div className="mt-4">
                {children}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Portal; 