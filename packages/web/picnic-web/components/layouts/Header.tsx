'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/contexts/AuthContext';
import { useLanguageStore } from '@/stores/languageStore';
import {
  ProfileImageContainer,
  DefaultAvatar,
} from '@/components/ui/ProfileImageContainer';
import PortalMenuItem from '@/components/features/PortalMenuItem';
import LanguageSelector from '@/components/features/LanguageSelector';
import { PORTAL_MENU } from '@/config/navigation';
import { Menu as MenuIcon } from 'lucide-react';

const Header = () => {
  const { authState } = useAuth();
  const { t } = useLanguageStore();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  return (
    <header className='border-b border-gray-200 bg-white relative'>
      <div className='container mx-auto px-2 sm:px-4 py-2'>
        <div className='flex-1 overflow-x-auto py-1 scrollbar-hide'>
          <div className='flex flex-col sm:flex-row w-full gap-2 sm:gap-4'>
            {/* 로고와 모바일 메뉴 버튼 */}
            <div className='flex items-center justify-between w-full sm:w-auto'>
              <div className='flex items-center space-x-2'>
                <Link href="/">
                  <Image
                    src='/images/logo.png'
                    alt='logo'
                    width={40}
                    height={40}
                    priority
                    className='w-8 h-8 sm:w-10 sm:h-10'
                  />
                </Link>
              </div>

              {/* 모바일 메뉴 버튼 */}
              <button
                className='sm:hidden p-2 rounded-md hover:bg-gray-100'
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              >
                <svg
                  className='w-6 h-6'
                  fill='none'
                  stroke='currentColor'
                  viewBox='0 0 24 24'
                >
                  <path
                    strokeLinecap='round'
                    strokeLinejoin='round'
                    strokeWidth={2}
                    d='M4 6h16M4 12h16M4 18h16'
                  />
                </svg>
              </button>
            </div>

            {/* 모바일 메뉴 */}
            <div
              className={`sm:hidden w-full ${
                isMobileMenuOpen ? 'block' : 'hidden'
              }`}
            >
              <div className='flex flex-col space-y-2 py-2'>
                {PORTAL_MENU.map((menuItem) => {
                  const isAdminMenu = [
                    'community',
                    'pic',
                    'novel',
                  ].includes(menuItem.type);
                  if (
                    isAdminMenu &&
                    (!authState.isAuthenticated || !authState.user?.isAdmin)
                  ) {
                    return null;
                  }
                  return (
                    <PortalMenuItem
                      key={menuItem.path}
                      portalType={menuItem.type}
                    />
                  );
                })}
              </div>
            </div>

            {/* 데스크톱 메뉴 */}
            <div className='hidden sm:flex items-center space-x-4 flex-1'>
              {PORTAL_MENU.map((menuItem) => {
                const isAdminMenu = ['community', 'pic', 'novel'].includes(
                  menuItem.type,
                );
                if (
                  isAdminMenu &&
                  (!authState.isAuthenticated || !authState.user?.isAdmin)
                ) {
                  return null;
                }
                return (
                  <PortalMenuItem
                    key={menuItem.path}
                    portalType={menuItem.type}
                  />
                );
              })}
            </div>

            {/* 우측 메뉴 */}
            <div className='flex items-center space-x-2 sm:space-x-4 justify-end'>
              <LanguageSelector />

              {authState.isAuthenticated ? (
                <Link href='/mypage'>
                  {authState.user?.avatarUrl ? (
                    <ProfileImageContainer
                      avatarUrl={authState.user.avatarUrl}
                      width={32}
                      height={32}
                      borderRadius={8}
                    />
                  ) : (
                    <DefaultAvatar width={32} height={32} />
                  )}
                </Link>
              ) : (
                <Link href='/mypage'>
                  <div className='p-2 hover:bg-gray-100 rounded-lg transition-colors cursor-pointer border border-gray-200'>
                    <MenuIcon className="w-6 h-6 text-gray-700" />
                  </div>
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header; 