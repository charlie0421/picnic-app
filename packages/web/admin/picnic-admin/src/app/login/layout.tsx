'use client'; // 로그인 폼 상호작용을 위해 클라이언트 컴포넌트 필요 가정

import React, { Suspense } from 'react';
import { AntdRegistry } from '@ant-design/nextjs-registry';
import { ConfigProvider, App, Layout } from 'antd';
import { ColorModeContextProvider } from '@contexts/color-mode';
import { cookies } from 'next/headers';
import '@refinedev/antd/dist/reset.css';

// 로그인 레이아웃 메타데이터 (필요시)
// export const metadata = { ... };

export default function LoginLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  // 로그인 레이아웃에서는 테마 쿠키를 읽지 않거나 다르게 처리할 수 있음
  // const cookieStore = cookies();
  // const theme = cookieStore.get('theme');
  // const defaultMode = theme?.value === 'dark' ? 'dark' : 'light';
  const defaultMode = 'light'; // 로그인 페이지는 라이트 모드 고정 등

  return (
    // <html>, <body>는 Next.js가 자동으로 처리
    <Suspense fallback={<div>Loading...</div>}>
      <AntdRegistry>
        <ColorModeContextProvider defaultMode={defaultMode}>
          <ConfigProvider>
            <App>
              {/* 최소한의 Layout으로 감싸거나 직접 children 렌더링 */}
              <Layout
                style={{
                  minHeight: '100vh',
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                }}
              >
                {children}
              </Layout>
            </App>
          </ConfigProvider>
        </ColorModeContextProvider>
      </AntdRegistry>
    </Suspense>
  );
}
