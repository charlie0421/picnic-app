'use client';

import React from 'react';
import { ThemedLayoutV2 } from '@refinedev/antd';
import { Spin } from 'antd';
import { usePermissionLoading } from '@/contexts/PermissionLoadingContext';
import { Header } from '@/components/header';

const MainLayout: React.FC<React.PropsWithChildren> = ({ children }) => {
  const { isLoadingPermissions } = usePermissionLoading();

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

  // 로딩 완료 후 메인 레이아웃 렌더링
  return <ThemedLayoutV2 Header={Header}>{children}</ThemedLayoutV2>;
};

export default MainLayout;
