'use client';

import React from 'react';
import Image from 'next/image';
import { getCdnImageUrl } from '@/utils/api/image';

interface RewardImageGalleryProps {
  images: string[];
  title: string;
  currentImageIndex: number;
  setCurrentImageIndex: (index: number) => void;
}


const RewardImageGallery: React.FC<RewardImageGalleryProps> = ({
  images,
  title,
  currentImageIndex,
  setCurrentImageIndex,
}) => {
  return (
    <div>
      <div className='relative w-full aspect-video bg-gray-100 rounded-lg overflow-hidden mb-4'>
        {/* 이전 이미지 버튼 */}
        {images.length > 1 && (
          <button
            onClick={() =>
              setCurrentImageIndex(
                currentImageIndex === 0 ? images.length - 1 : currentImageIndex - 1,
              )
            }
            className='absolute left-2 top-1/2 z-20 transform -translate-y-1/2 bg-black/70 text-white rounded-full p-2 shadow-md hover:bg-black transition'
            aria-label='이전 이미지'
          >
            <svg
              xmlns='http://www.w3.org/2000/svg'
              fill='none'
              viewBox='0 0 24 24'
              strokeWidth={1.5}
              stroke='currentColor'
              className='w-6 h-6'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                d='M15.75 19.5L8.25 12l7.5-7.5'
              />
            </svg>
          </button>
        )}

        {images.length > 0 && (
          <Image
            src={getCdnImageUrl(images[currentImageIndex], 300)}
            alt={`${title} 이미지 ${currentImageIndex + 1}`}
            fill
            className='object-contain'
            priority
          />
        )}

        {/* 다음 이미지 버튼 */}
        {images.length > 1 && (
          <button
            onClick={() =>
              setCurrentImageIndex(
                currentImageIndex === images.length - 1 ? 0 : currentImageIndex + 1,
              )
            }
            className='absolute right-2 top-1/2 z-20 transform -translate-y-1/2 bg-black/70 text-white rounded-full p-2 shadow-md hover:bg-black transition'
            aria-label='다음 이미지'
          >
            <svg
              xmlns='http://www.w3.org/2000/svg'
              fill='none'
              viewBox='0 0 24 24'
              strokeWidth={1.5}
              stroke='currentColor'
              className='w-6 h-6'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                d='M8.25 4.5l7.5 7.5-7.5 7.5'
              />
            </svg>
          </button>
        )}

        {/* 이미지 카운터 표시 */}
        {images.length > 1 && (
          <div className='absolute bottom-2 right-2 bg-black/60 text-white px-3 py-1 rounded-full text-sm'>
            {currentImageIndex + 1} / {images.length}
          </div>
        )}
      </div>

      {images.length > 1 && (
        <div className='flex overflow-x-auto space-x-2 py-2'>
          {images.map((image, index) => (
            <div
              key={index}
              onClick={() => setCurrentImageIndex(index)}
              className={`relative w-20 h-20 flex-shrink-0 cursor-pointer rounded-md overflow-hidden ${
                index === currentImageIndex ? 'ring-2 ring-primary' : ''
              }`}
            >
              <Image
                src={getCdnImageUrl(image, 200)}
                alt={`${title} 썸네일 ${index + 1}`}
                fill
                className='object-cover'
              />
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default RewardImageGallery; 