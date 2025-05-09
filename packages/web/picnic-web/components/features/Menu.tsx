'use client';

import React from 'react';
import Link from 'next/link';
import {usePathname} from 'next/navigation';
import CurrentTime from '@/components/features/CurrentTime';
import {useLanguageStore} from '@/stores/languageStore';
import menuConfig from '@/config/menu.json';

/**
 * 투표 페이지 메뉴 컴포넌트
 * 투표홈, 픽차트, 미디어, 상점 등의 메뉴 항목과 현재 시간을 표시합니다.
 */
const Menu: React.FC = () => {
  const { t } = useLanguageStore();
  const pathname = usePathname();

  // 현재 경로에 따라 메뉴 항목의 활성 상태 결정
  const isActive = (path: string) => {
    // 언어 코드를 제외한 경로 비교
    const currentPath = pathname.split('/').slice(2).join('/');
    const targetPath = path.split('/').slice(1).join('/');
    return currentPath.startsWith(targetPath);
  };

  // 투표 포탈의 서브메뉴 가져오기
  const votePortal = menuConfig.portals.find(portal => portal.type === 'vote');
  const subMenus = votePortal?.subMenus || [];

  return (
    <div className='flex justify-between items-center py-0'>
      <div className='flex overflow-x-auto scrollbar-hide whitespace-nowrap'>
        {subMenus.map((menuItem) => (
          <Link
            key={menuItem.key}
            href={menuItem.path}
            className={`px-5 py-2 text-sm sm:text-base ${
              isActive(menuItem.path) &&
              // 투표홈은 하위 경로가 아닐 때만 활성화
              (menuItem.key !== 'vote' ||
                (!isActive('/vote/chart') && !isActive('/rewards')))
                ? 'font-medium text-primary border-b-2 border-primary'
                : 'text-gray-500 hover:text-primary hover:border-b-2 hover:border-primary'
            }`}
          >
            {menuItem.i18nKey ? t(menuItem.i18nKey) : menuItem.name}
          </Link>
        ))}
      </div>
      <CurrentTime />
    </div>
  );
};

export default Menu;
