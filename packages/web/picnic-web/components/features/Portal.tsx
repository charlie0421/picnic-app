'use client';

import React, { useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useParams, usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigation } from '@/contexts/NavigationContext';
import { useLanguageStore } from '@/stores/languageStore';
import {
  ProfileImageContainer,
  DefaultAvatar,
} from '@/components/ui/ProfileImageContainer';
import PortalMenuItem from '@/components/features/PortalMenuItem';
import LanguageSelector from '@/components/features/LanguageSelector';
import ExclusiveOpenBadge from '@/components/features/ExclusiveOpenBadge';
import Menu from '@/components/features/Menu';
import { PortalType } from '@/utils/enums';
import {
  PORTAL_MENU,
  getPortalTypeFromPath
} from '@/config/navigation';

// 환경 설정 확인 (개발 환경인지)
const isDev = process.env.NODE_ENV !== 'production';

interface PortalProps {
  children: React.ReactNode;
}

const Portal: React.FC<PortalProps> = ({ children }) => {
  const { authState } = useAuth();
  const { navigationState, setCurrentPortalType } = useNavigation();
  const { t } = useLanguageStore();
  const pathname = usePathname();

  // 경로에 따라 현재 포탈 타입 설정
  useEffect(() => {
    const portalType = getPortalTypeFromPath(pathname);
    setCurrentPortalType(portalType);
  }, [pathname, setCurrentPortalType]);

  return (
    <div className='bg-gradient-to-b from-blue-50 to-white min-h-screen'>
      <div className='max-w-6xl mx-auto bg-white shadow-md min-h-screen'>
        <header className='border-b border-gray-200 bg-white'>
          <div className='container mx-auto flex items-center px-4 py-2'>
            <div className='flex-1 overflow-x-auto py-1 scrollbar-hide'>
              <div className='flex items-center justify-between w-full'>
                <div className='flex items-center space-x-1'>
                  <div className='flex items-center space-x-1'>
                    <Image
                      src='/images/logo.png'
                      alt='logo'
                      width={40}
                      height={40}
                      priority
                    />
                  </div>
                  {/* 개발 환경 표시 */}
                  {/* {isDev && <div className="text-xs text-gray-400 mr-2">개발</div>} */}

                  {/* 포탈 메뉴 아이템들 */}
                  {PORTAL_MENU.map((menuItem) => (
                    <PortalMenuItem
                      key={menuItem.path}
                      portalType={menuItem.type}
                    />
                  ))}

                </div>

                <div className='flex items-center space-x-4'>
                  {/* 언어 선택기 추가 */}
                  <LanguageSelector />

                  {authState.isAuthenticated ? (
                    <Link href='/mypage'>
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
                    <Link href='/login'>
                      <div className='px-3 py-1.5 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors'>
                        {t('button_login')}
                      </div>
                    </Link>
                  )}
                </div>
              </div>
            </div>
          </div>
        </header>
        <main className='container mx-auto px-4 py-0'>
          <div className='flex flex-col'>
            <div className='w-full'>
              {/* 배타 오픈 뱃지 */}
              <div className="flex justify-center py-4">
                <ExclusiveOpenBadge />
              </div>
              {/* 서브 메뉴 */}
              <div className='bg-gray-50 border-b'>
                <div className='container mx-auto px-0'>
                  <Menu />
                </div>
              </div>
              {/* 메인 콘텐츠 */}
              {children}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Portal;
