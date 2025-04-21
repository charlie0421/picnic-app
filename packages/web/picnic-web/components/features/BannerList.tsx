'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Banner } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

interface BannerListProps {
  banners: Banner[];
}

const BannerList: React.FC<BannerListProps> = ({ banners }) => {
  return (
    <section>
      <div className='mb-4'>
        <div className='flex justify-end items-center mb-4'>
          <Link href='/banner' className='text-primary text-sm hover:underline'>
            전체보기
          </Link>
        </div>

        {banners.length === 0 ? (
          <div className='bg-gray-100 p-6 rounded-lg text-center'>
            <p className='text-gray-500'>현재 표시할 배너가 없습니다.</p>
          </div>
        ) : (
          <div className='grid grid-cols-1 sm:grid-cols-2 gap-4'>
            {banners.map((banner: Banner) => {
              const image = banner.image as { [key: string]: string } | null;
              return (
                <Link key={banner.id} href={banner.link || '#'}>
                  <div className='relative w-full pb-[50.9%] rounded-lg bg-gray-200 overflow-hidden hover:shadow-lg transition-shadow'>
                    {image ? (
                      <Image
                        src={getCdnImageUrl(getLocalizedString(image), 786)}
                        alt={
                          typeof banner.title === 'string'
                            ? banner.title
                            : '배너'
                        }
                        fill
                        sizes='(max-width: 640px) 100vw, 50vw'
                        className='object-cover'
                        priority
                      />
                    ) : (
                      <div className='absolute inset-0 flex items-center justify-center'>
                        <span className='text-gray-600'>
                          {typeof banner.title === 'string'
                            ? banner.title
                            : '배너'}
                        </span>
                      </div>
                    )}
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </section>
  );
};

export default BannerList;
