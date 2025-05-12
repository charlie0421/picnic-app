'use client';

import React, { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigation } from '@/contexts/NavigationContext';
import { useLanguageStore } from '@/stores/languageStore';
import Footer from '@/components/layouts/Footer';
import ExclusiveOpenBadge from '@/components/layouts/ExclusiveOpenBadge';
import Menu from '@/components/features/vote/Menu';
import { getPortalTypeFromPath } from '@/config/navigation';
import Header from '@/components/layouts/Header';
import VotePopup from '@/components/features/vote/dialogs/VotePopup';
import { getPopups } from '@/utils/api/queries';
import { getLocalizedString } from '@/utils/api/strings';
import { getCdnImageUrl } from '@/utils/api/image';

const MainLayout = ({ children }: { children: React.ReactNode }) => {
  const { setCurrentPortalType } = useNavigation();
  const pathname = usePathname();
  const [isPopupOpen, setIsPopupOpen] = useState(false);
  const [popupResource, setPopupResource] = useState<any>(null);

  useEffect(() => {
    const portalType = getPortalTypeFromPath(pathname);
    setCurrentPortalType(portalType);
  }, [pathname, setCurrentPortalType]);

  useEffect(() => {
    async function fetchPopupResource() {
      try {
        const popups = await getPopups();
        if (!popups || popups.length === 0) return;
        const popup = popups[0];
        setPopupResource({
          ...popup,
          popupKey: popup.id,
          imageUrl: getCdnImageUrl(getLocalizedString(popup.image)),
          title: popup.title,
          content: popup.content,
          startAt: popup.startAt,
          stopAt: popup.stopAt,
          platform: popup.platform || 'all',
        });
      } catch (e) {
        // 에러 무시
      }
    }
    fetchPopupResource();
  }, []);

  const checkPopupVisible = (resource: any) => {
    if (!resource) return false;
    const now = new Date();
    const start = new Date(resource.startAt);
    const stop = new Date(resource.stopAt);
    const platform = resource.platform;
    const popupKey = resource.popupKey;
    const hideUntil = typeof window !== 'undefined' ? localStorage.getItem(`hide_popup_${popupKey}`) : null;
    if (hideUntil && new Date(hideUntil) > now) return false;
    if (now < start || now > stop) return false;
    if (!(platform === 'all' || platform === 'web')) return false;
    return true;
  };

  useEffect(() => {
    if (popupResource && checkPopupVisible(popupResource)) {
      setIsPopupOpen(true);
    }
  }, [popupResource]);

  const handleCloseFor7Days = () => {
    if (!popupResource) return;
    const popupKey = popupResource.popupKey;
    const hideUntil = new Date();
    hideUntil.setDate(hideUntil.getDate() + 7);
    if (typeof window !== 'undefined') {
      localStorage.setItem(`hide_popup_${popupKey}`, hideUntil.toISOString());
    }
    setIsPopupOpen(false);
  };

  return (
    <div className='bg-gradient-to-b from-blue-50 to-white relative'>
      {popupResource && (
        <VotePopup
          isOpen={isPopupOpen}
          onClose={() => setIsPopupOpen(false)}
          onCloseFor7Days={handleCloseFor7Days}
          imageUrl={getLocalizedString(popupResource.imageUrl)}
          title={getLocalizedString(popupResource.title)}
          content={getLocalizedString(popupResource.content)}
        />
      )}
      <div className='max-w-6xl mx-auto bg-white shadow-md'>
        <Header />
        <main className='container mx-auto px-2 sm:px-4 py-0 min-h-screen'>
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

export default MainLayout;