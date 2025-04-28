import React from 'react';
import Image from 'next/image';
import { settings } from '@/config/settings';

interface ProfileImageContainerProps {
  src: string;
  alt: string;
  size?: 'sm' | 'md' | 'lg';
}

const ProfileImageContainer: React.FC<ProfileImageContainerProps> = ({
  src,
  alt,
  size = 'md',
}) => {
  return (
    <div className={`relative rounded-full overflow-hidden ${settings.layout.profileImage.sizes[size]}`}>
      <Image
        src={src}
        alt={alt}
        fill
        className="object-cover"
      />
    </div>
  );
};

export default ProfileImageContainer; 