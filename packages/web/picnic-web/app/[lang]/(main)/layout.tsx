'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import {
  useNavigation,
  NavigationProvider,
} from '@/contexts/NavigationContext';
import { useLanguageStore } from '@/stores/languageStore';
import { AuthProvider } from '@/contexts/AuthContext';
import Footer from '@/components/layouts/Footer';
import {
  ProfileImageContainer,
  DefaultAvatar,
} from '@/components/ui/ProfileImageContainer';
import PortalMenuItem from '@/components/features/PortalMenuItem';
import LanguageSelector from '@/components/features/LanguageSelector';
import ExclusiveOpenBadge from '@/components/features/ExclusiveOpenBadge';
import Menu from '@/components/features/Menu';
import { PortalType } from '@/utils/enums';
import { PORTAL_MENU, getPortalTypeFromPath } from '@/config/navigation';
import { Menu as MenuIcon } from 'lucide-react';
import { Analytics } from '@vercel/analytics/react';
import Header from '@/components/layouts/Header';

const MainContent = ({ children }: { children: React.ReactNode }) => {
  const { authState } = useAuth();
  const { setCurrentPortalType } = useNavigation();
  const { t } = useLanguageStore();
  const pathname = usePathname();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const portalType = getPortalTypeFromPath(pathname);
    setCurrentPortalType(portalType);
  }, [pathname, setCurrentPortalType]);

  return (
    <div className='bg-gradient-to-b from-blue-50 to-white relative'>
      <div className='max-w-6xl mx-auto bg-white shadow-md'>
        <Header />
        <main className='container mx-auto px-2 sm:px-4 py-0'>
          <div className='flex flex-col'>
            <div className='w-full'>
              {/* 배타 오픈 뱃지 */}
              <div className='flex justify-center py-1 sm:py-2'>
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
      <Footer />
    </div>
  );
};

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <MainContent>{children}</MainContent>;
}
