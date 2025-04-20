'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { PortalType } from '@/utils/enums';

interface PortalMenuItemProps {
  portalType: PortalType;
}

const getPortalTypeInfo = (type: PortalType) => {
  switch (type) {
    case PortalType.VOTE:
      return {
        name: 'VOTE',
        path: '/vote',
      };
    case PortalType.COMMUNITY:
      return {
        name: 'COMMUNITY',
        path: '/community',
      };
    case PortalType.PIC:
      return {
        name: 'PIC',
        path: '/pic',
      };
    case PortalType.NOVEL:
      return {
        name: 'NOVEL',
        path: '/novel',
      };
    case PortalType.MYPAGE:
      return {
        name: 'MYPAGE',
        path: '/mypage',
      };
    case PortalType.MEDIA:
      return {
        name: 'MEDIA',
        path: '/media',
      };
    case PortalType.SHOP:
      return {
        name: 'SHOP',
        path: '/shop',
      };
    default:
      return {
        name: '',
        path: '/',
      };
  }
};

const PortalMenuItem: React.FC<PortalMenuItemProps> = ({ portalType }) => {
  const pathName = usePathname();
  const { name, path } = getPortalTypeInfo(portalType);
  const isActive = pathName.startsWith(path);

  return (
    <Link href={path}>
      <div
        className={`px-4 py-2 mx-1 cursor-pointer rounded-lg transition-colors ${
          isActive ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-500'
        }`}
      >
        {name}
      </div>
    </Link>
  );
};

export default PortalMenuItem; 