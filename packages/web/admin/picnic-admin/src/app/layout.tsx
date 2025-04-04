import { DevtoolsProvider } from '@providers/devtools';
import { useNotificationProvider } from '@refinedev/antd';
import { Refine } from '@refinedev/core';
import { RefineKbar, RefineKbarProvider } from '@refinedev/kbar';
import routerProvider from '@refinedev/nextjs-router';
import { Metadata } from 'next';
import { cookies } from 'next/headers';
import React, { Suspense } from 'react';

import { AntdRegistry } from '@ant-design/nextjs-registry';
import { App, ConfigProvider } from 'antd';
import { ColorModeContextProvider } from '@contexts/color-mode';
import { authProviderClient } from '@providers/auth-provider/auth-provider.client';
import { dataProvider } from '@providers/data-provider';
import '@refinedev/antd/dist/reset.css';
import { ThemedLayoutV2 } from '@refinedev/antd';
import { Header } from '@/components/header';

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
                <ConfigProvider>
                  <App>
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
                          {
                            name: 'media',
                            list: '/media',
                            create: '/media/create',
                            edit: '/media/edit/:id',
                            show: '/media/show/:id',
                            meta: {
                              canDelete: true,
                              label: '미디어 관리',
                              list: {
                                label: '미디어 목록',
                              },
                              create: {
                                label: '미디어 추가',
                              },
                              edit: {
                                label: '미디어 수정',
                              },
                              show: {
                                label: '미디어 상세',
                              },
                            },
                          },
                          {
                            name: 'artist_group',
                            list: '/artist-group',
                            create: '/artist-group/create',
                            edit: '/artist-group/edit/:id',
                            show: '/artist-group/show/:id',
                            meta: {
                              canDelete: true,
                              label: '아티스트 그룹 관리',
                              list: {
                                label: '아티스트 그룹 목록',
                              },
                              create: {
                                label: '아티스트 그룹 추가',
                              },
                              edit: {
                                label: '아티스트 그룹 수정',
                              },
                              show: {
                                label: '아티스트 그룹 상세',
                              },
                            },
                          },
                          {
                            name: 'artist',
                            list: '/artist',
                            create: '/artist/create',
                            edit: '/artist/edit/:id',
                            show: '/artist/show/:id',
                            meta: {
                              canDelete: true,
                              label: '아티스트 관리',
                              list: {
                                label: '아티스트 목록',
                              },
                              create: {
                                label: '아티스트 추가',
                              },
                              edit: {
                                label: '아티스트 수정',
                              },
                              show: {
                                label: '아티스트 상세',
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
                        <ThemedLayoutV2 Header={Header}>
                          {children}
                        </ThemedLayoutV2>
                        <RefineKbar />
                      </Refine>
                    </DevtoolsProvider>
                  </App>
                </ConfigProvider>
              </ColorModeContextProvider>
            </AntdRegistry>
          </RefineKbarProvider>
        </Suspense>
      </body>
    </html>
  );
}
