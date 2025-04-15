'use client';

import React, { FC, ReactNode } from 'react';
import { useCan } from '@refinedev/core';
import { Spin, Result } from 'antd';
import { usePathname } from 'next/navigation';

interface AuthorizePageProps {
  children: ReactNode;
  resource?: string;
  action: string;
  // 필요하다면 로딩 컴포넌트나 접근 거부 컴포넌트를 커스텀할 수 있도록 props 추가 가능
  // loadingComponent?: React.ReactNode;
  // accessDeniedComponent?: React.ReactNode;
}

export const AuthorizePage: FC<AuthorizePageProps> = ({
  children,
  resource: propResource,
  action,
  // loadingComponent = <DefaultLoading />,
  // accessDeniedComponent = <DefaultAccessDenied />,
}) => {
  const pathname = usePathname();

  // URL 경로에서 리소스 이름 추출
  const getResourceFromPath = () => {
    const pathParts = pathname.split('/');
    // app 폴더 이후의 첫 번째 세그먼트가 리소스 이름
    return pathParts[1] || '';
  };

  const resource = propResource || getResourceFromPath();

  const { data: canAccess, isLoading: isLoadingAccess } = useCan({
    resource,
    action,
  });

  // 기본 로딩 컴포넌트 (AuthorizePage 내부에 정의하거나 별도 파일로 분리 가능)
  const DefaultLoading = () => (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '80vh',
      }}
    >
      <Spin />
    </div>
  );

  // 기본 접근 거부 컴포넌트
  const DefaultAccessDenied = () => (
    <Result
      status='403'
      title='403'
      subTitle={`죄송합니다, 이 '${resource}'에 대한 '${action}' 작업을 수행할 권한이 없습니다.`}
    />
  );

  if (isLoadingAccess) {
    // return loadingComponent;
    return <DefaultLoading />;
  }

  if (!canAccess?.can) {
    // return accessDeniedComponent;
    return <DefaultAccessDenied />;
  }

  // 권한이 있으면 자식 컴포넌트(실제 페이지 내용) 렌더링
  return <>{children}</>;
};
