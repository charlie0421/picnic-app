'use client'; // 로그인 폼 상호작용을 위해 클라이언트 컴포넌트 필요 가정

import React, { Suspense } from 'react';
import { AntdRegistry } from '@ant-design/nextjs-registry';
import { ConfigProvider, App } from 'antd';
import { ColorModeContextProvider } from '@contexts/color-mode';
import '@refinedev/antd/dist/reset.css';

// 로그인 레이아웃 메타데이터 (필요시)
// export const metadata = { ... };

export default function LoginLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const defaultMode = 'light';

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <AntdRegistry>
        <ColorModeContextProvider defaultMode={defaultMode}>
          <ConfigProvider>
            <App>{children}</App>
          </ConfigProvider>
        </ColorModeContextProvider>
      </AntdRegistry>
    </Suspense>
  );
}
