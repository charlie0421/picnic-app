import React from 'react';
import Image from 'next/image';

interface ProfileImageContainerProps {
  avatarUrl: string;
  width: number;
  height: number;
  borderRadius?: number;
}

export const ProfileImageContainer: React.FC<ProfileImageContainerProps> = ({
  avatarUrl,
  width,
  height,
  borderRadius = 0,
}) => {
  return (
    <div style={{ borderRadius, overflow: 'hidden' }}>
      <Image
        src={avatarUrl}
        alt="프로필 이미지"
        width={width}
        height={height}
        className="object-cover"
      />
    </div>
  );
};

export const DefaultAvatar: React.FC<{ width: number; height: number }> = ({ width, height }) => {
  return (
    <div className="bg-gray-200 flex items-center justify-center" style={{ width, height }}>
      <span className="text-gray-500">👤</span>
    </div>
  );
}; 