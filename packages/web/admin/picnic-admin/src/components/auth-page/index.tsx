'use client';
import { AuthPage as AuthPageBase } from '@refinedev/antd';
import type { AuthPageProps } from '@refinedev/core';
import Image from 'next/image';

export const AuthPage = (props: AuthPageProps) => {
  return (
    <AuthPageBase
      {...props}
      title='Picnic Admin Panel'
      renderContent={(content: React.ReactNode) => (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '16px',
          }}
        >
          <Image
            src='/app_icon.png'
            alt='Picnic Admin Panel'
            width={64}
            height={64}
          />
          {content}
        </div>
      )}
    />
  );
};
