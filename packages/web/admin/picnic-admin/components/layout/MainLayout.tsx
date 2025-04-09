'use client';

import React from 'react';
import { ThemedLayoutV2, ThemedSiderV2 } from '@refinedev/antd';
import { Spin, Grid, theme } from 'antd';
import { usePermissionLoading } from '@/contexts/PermissionLoadingContext';
import { Header } from '@/components/header';
import Image from 'next/image';
import { useIsAuthenticated } from '@refinedev/core';

const { useBreakpoint } = Grid;
const { useToken } = theme;

const MainLayout: React.FC<React.PropsWithChildren> = ({ children }) => {
  const { isLoadingPermissions } = usePermissionLoading();
  const { data: isAuthenticated } = useIsAuthenticated();
  const screens = useBreakpoint();
  const isMobile = !screens.md;
  const { token } = useToken();

  if (isLoadingPermissions) {
    // 로딩 중일 때 전체 화면 스피너 표시
    return (
      <div
        style={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          height: '100vh',
        }}
      >
        <Spin size='large' />
      </div>
    );
  }

  const Title = () => (
    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
      <Image
        src='/app_icon.png'
        alt='Picnic Admin Panel'
        width={32}
        height={32}
      />
      <span>Picnic Admin Panel</span>
    </div>
  );

  // 로딩 완료 후 메인 레이아웃 렌더링
  return (
    <ThemedLayoutV2
      Header={Header}
      Title={Title}
      Sider={isAuthenticated ? ThemedSiderV2 : () => null}
    >
      <div style={{
        paddingTop: isMobile ? '32px' : '16px',
        minHeight: '100vh',
        backgroundColor: token.colorBgLayout
      }}>
        {children}
      </div>
    </ThemedLayoutV2>
  );
};

export default MainLayout;
