import { DevtoolsProvider } from '@providers/devtools';
import { useNotificationProvider } from '@refinedev/antd';
import { Refine } from '@refinedev/core';
import { RefineKbar, RefineKbarProvider } from '@refinedev/kbar';
import routerProvider from '@refinedev/nextjs-router';
import { Metadata } from 'next';
import { cookies } from 'next/headers';
import React, { Suspense } from 'react';

import { AntdRegistry } from '@ant-design/nextjs-registry';
import { ColorModeContextProvider } from '@contexts/color-mode';
import { authProviderClient } from '@providers/auth-provider/auth-provider.client';
import { dataProvider } from '@providers/data-provider';
import '@refinedev/antd/dist/reset.css';

export const metadata: Metadata = {
  title: 'Picnic Admin',
  description: 'Picnic Admin',
  icons: {
    icon: '/favicon.ico',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookieStore = cookies();
  const theme = cookieStore.get('theme');
  const defaultMode = theme?.value === 'dark' ? 'dark' : 'light';

  return (
    <html lang='en'>
      <body>
        <Suspense>
          <RefineKbarProvider>
            <AntdRegistry>
              <ColorModeContextProvider defaultMode={defaultMode}>
                <DevtoolsProvider>
                  <Refine
                    routerProvider={routerProvider}
                    authProvider={authProviderClient}
                    dataProvider={dataProvider}
                    notificationProvider={useNotificationProvider}
                    resources={[
                      {
                        name: 'vote',
                        list: '/vote',
                        create: '/vote/create',
                        edit: '/vote/edit/:id',
                        show: '/vote/show/:id',
                        meta: {
                          canDelete: true,
                          label: '투표관리',
                          list: {
                            label: '투표관리',
                          },
                          create: {
                            label: '투표생성',
                          },
                          edit: {
                            label: '투표수정',
                          },
                          show: {
                            label: '투표조회',
                          },
                        },
                      },
                    ]}
                    options={{
                      syncWithLocation: true,
                      warnWhenUnsavedChanges: true,
                      useNewQueryKeys: true,
                      projectId: 'eFoHzB-2HcEeI-OFQDmB',
                      title: {
                        icon: (
                          <img
                            src='/icons/app_icon.png'
                            alt='Picnic Admin'
                            style={{ width: 28, height: 28 }}
                          />
                        ),
                        text: 'Picnic Admin',
                      },
                    }}
                  >
                    {children}
                    <RefineKbar />
                  </Refine>
                </DevtoolsProvider>
              </ColorModeContextProvider>
            </AntdRegistry>
          </RefineKbarProvider>
        </Suspense>
      </body>
    </html>
  );
}
