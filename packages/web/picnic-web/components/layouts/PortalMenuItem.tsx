'use client';

import Link from 'next/link';
import {usePathname} from 'next/navigation';
import {PortalType} from '@/utils/enums';
import {isVoteRelatedPath, PORTAL_MENU} from '@/config/navigation';
import menuConfig from '@/config/menu.json';

interface PortalMenuItemProps {
  portalType: PortalType;
}

const PortalMenuItem: React.FC<PortalMenuItemProps> = ({ portalType }) => {
  const pathName = usePathname();

  // 설정에서 메뉴 정보 가져오기
  const menuItem = PORTAL_MENU.find((item) => item.type === portalType);
  const portalConfig = menuConfig.portals.find(portal => portal.type === portalType);

  if (!menuItem || !portalConfig) return null;

  // 특수 케이스: 리워드 페이지 방문 시 VOTE 메뉴 활성화
  const isActive =
    pathName.startsWith(menuItem.path) ||
    (portalType === PortalType.VOTE && isVoteRelatedPath(pathName));

  return (
    <Link href={menuItem.path}>
      <div
        className={`px-2 py-1 mx-1 cursor-pointer rounded-lg transition-colors ${
          isActive ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-500'
        }`}
      >
        {menuItem.name}
      </div>
    </Link>
  );
};

export default PortalMenuItem;
