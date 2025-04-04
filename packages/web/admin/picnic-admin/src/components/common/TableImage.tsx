'use client';

import React from 'react';
import { Image } from 'antd';
import { getImageUrl } from '@/utils/image';

interface TableImageProps {
  src?: string;
  alt?: string;
  width?: number;
  height?: number;
  borderRadius?: string | number;
  objectFit?: 'cover' | 'contain' | 'fill' | 'none' | 'scale-down';
  previewEnabled?: boolean;
  previewMask?: string;
}

export const TableImage: React.FC<TableImageProps> = ({
  src,
  alt = '이미지',
  width = 100,
  height = 100,
  borderRadius = '4px',
  objectFit = 'cover',
  previewEnabled = true,
  previewMask = '확대',
}) => {
  if (!src) return '-';

  return (
    <Image
      src={getImageUrl(src)}
      alt={alt}
      width={width}
      height={height}
      style={{ objectFit, borderRadius }}
      preview={
        previewEnabled
          ? {
              mask: previewMask,
            }
          : false
      }
    />
  );
};

export default TableImage;
