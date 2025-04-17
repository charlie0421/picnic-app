'use client';

import React, { useEffect } from 'react';
import { ThemedLayoutV2, ThemedSiderV2 } from '@refinedev/antd';
import { Spin, Grid, theme } from 'antd';
import { usePermissionLoading } from '@/contexts/PermissionLoadingContext';
import { Header } from '@/components/header';
import Image from 'next/image';
import { useIsAuthenticated } from '@refinedev/core';
import { useRouter, usePathname } from 'next/navigation';

const { useBreakpoint } = Grid;
const { useToken } = theme;

// Title 컴포넌트를 분리하여 조건부 렌더링 문제 방지
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

// Sider를 조건부 렌더링 대신 함수형 컴포넌트로 분리
const ConditionalSider = ({ isAuthenticated }: { isAuthenticated: boolean }) => {
  if (isAuthenticated) {
    return <ThemedSiderV2 />;
  }
  return null;
};

const MainLayout: React.FC<React.PropsWithChildren> = ({ children }) => {
  const { isLoadingPermissions } = usePermissionLoading();
  const { data: isAuthenticated, isLoading: isAuthLoading } = useIsAuthenticated();
  const screens = useBreakpoint();
  const isMobile = !screens.md;
  const { token } = useToken();
  const router = useRouter();
  const pathname = usePathname();

  // authenticated 상태 확인을 위한 변수
  const authenticated = isAuthenticated?.authenticated === true;

  // 인증 상태를 확인하고 로그인되지 않았으면 리다이렉트
  useEffect(() => {
    // 로그인 페이지가 아닌 경우에만 리다이렉트 검사
    if (pathname !== '/login' && !isAuthLoading && isAuthenticated !== undefined) {
      if (isAuthenticated.authenticated === false) {
        router.push('/login');
      }
    }
  }, [isAuthenticated, isAuthLoading, router, pathname]);

  if (isLoadingPermissions || isAuthLoading) {
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

  // 로그인 페이지가 아닌데 인증되지 않았으면 빈 화면 표시 (리다이렉트 처리 중)
  if (pathname !== '/login' && !authenticated) {
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

  // 로딩 완료 후 메인 레이아웃 렌더링
  return (
    <ThemedLayoutV2
      Header={Header}
      Title={Title}
      Sider={() => <ConditionalSider isAuthenticated={authenticated} />}
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
