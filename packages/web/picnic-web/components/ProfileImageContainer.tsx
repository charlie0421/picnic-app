'use client';

import Image from 'next/image';

interface ProfileImageContainerProps {
  avatarUrl?: string;
  width?: number;
  height?: number;
  borderRadius?: number;
}

export const ProfileImageContainer: React.FC<ProfileImageContainerProps> = ({
  avatarUrl,
  width = 40,
  height = 40,
  borderRadius = 8,
}) => {
  return (
    <div
      style={{
        width,
        height,
        borderRadius,
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      <Image
        src={avatarUrl || '/images/default-avatar.png'}
        alt="Profile"
        fill
        sizes={`${Math.max(width, height)}px`}
        style={{ objectFit: 'cover' }}
      />
    </div>
  );
};

export const DefaultAvatar: React.FC<{ width?: number; height?: number }> = ({
  width = 40,
  height = 40,
}) => {
  return (
    <div
      style={{
        width,
        height,
        borderRadius: 8,
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      <Image
        src="/images/default-avatar.png"
        alt="Default Avatar"
        fill
        sizes={`${Math.max(width, height)}px`}
        style={{ objectFit: 'cover' }}
      />
    </div>
  );
}; 