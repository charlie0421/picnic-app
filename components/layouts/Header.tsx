'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import {usePathname} from 'next/navigation';
import {useAuth} from '@/lib/supabase/auth-provider';
import {useLanguageStore} from '@/stores/languageStore';
import {DefaultAvatar, ProfileImageContainer,} from '@/components/ui/ProfileImageContainer';
import PortalMenuItem from './PortalMenuItem';
import {PORTAL_MENU} from '@/config/navigation';
import {Menu as MenuIcon} from 'lucide-react';
import LanguageSelector from './LanguageSelector';

const Header: React.FC = () => {
  const { isAuthenticated, userProfile, signOut } = useAuth();
  const { currentLanguage } = useLanguageStore();
  const pathname = usePathname();

  return (
    <header className='border-b border-gray-200 bg-white relative'>
      <div className='container mx-auto px-2 sm:px-4 py-2'>
        <div className='flex-1 overflow-x-auto py-1 scrollbar-hide'>
          <div className='flex items-center w-full gap-2 sm:gap-4'>
            {/* 로고 */}
            <div className='flex items-center'>
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
            </div>

            {/* 메뉴 */}
            <div className='flex items-center space-x-4 flex-1'>
              {PORTAL_MENU.map((menuItem) => {
                const isAdminMenu = ['community', 'pic', 'novel'].includes(
                  menuItem.type,
                );
                if (
                  isAdminMenu &&
                  (!isAuthenticated || !userProfile?.isAdmin)
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
            <div className='flex items-center space-x-2 sm:space-x-4'>
              <LanguageSelector />

              {isAuthenticated ? (
                <Link href='/mypage'>
                  {userProfile?.avatarUrl ? (
                    <ProfileImageContainer
                      avatarUrl={userProfile.avatarUrl}
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
