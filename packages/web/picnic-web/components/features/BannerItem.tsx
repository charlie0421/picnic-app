'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Banner } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

interface BannerItemProps {
  banner: Banner;
}

const BannerItem: React.FC<BannerItemProps> = ({ banner }) => {
  const image = banner.image as { [key: string]: string } | null;

  return (
    <Link href={banner.link || '#'}>
      <div className="w-full h-[180px] rounded-lg bg-gray-200 overflow-hidden hover:shadow-lg transition-shadow">
        {image ? (
          <Image
            src={getCdnImageUrl(getLocalizedString(image), 320)}
            alt={typeof banner.title === 'string' ? banner.title : '배너'}
            width={320}
            height={180}
            className="w-full h-full object-cover"
            priority
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-gray-600">
              {typeof banner.title === 'string' ? banner.title : '배너'}
            </span>
          </div>
        )}
      </div>
    </Link>
  );
};

export default BannerItem; 