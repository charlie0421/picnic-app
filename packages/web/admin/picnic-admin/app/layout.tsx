import { DevtoolsProvider } from '@/providers/devtools';
import { useNotificationProvider } from '@refinedev/antd';
import { Refine } from '@refinedev/core';
import { RefineKbar, RefineKbarProvider } from '@refinedev/kbar';
import routerProvider from '@refinedev/nextjs-router';
import { Metadata } from 'next';
import { cookies } from 'next/headers';
import React, { Suspense } from 'react';

import { AntdRegistry } from '@ant-design/nextjs-registry';
import { App, ConfigProvider } from 'antd';
import { ColorModeContextProvider } from '@/contexts/color-mode';
import { authProviderClient } from '@/providers/auth-provider/auth-provider.client';
import { dataProvider } from '@/providers/data-provider';
import { accessControlProvider } from '@/providers/access-control-provider';
import '@refinedev/antd/dist/reset.css';
import { Header } from '@/components/header';
import { PermissionLoader } from '@/components/auth/PermissionLoader';
import { PermissionLoadingProvider } from '@/contexts/PermissionLoadingContext';
import MainLayout from '@/components/layout/MainLayout';

// antd 아이콘 불러오기
import {
  SettingOutlined,
  TeamOutlined,
  KeyOutlined,
  UserSwitchOutlined,
  LinkOutlined,
  VideoCameraOutlined,
  UserOutlined,
  GroupOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';

export const metadata: Metadata = {
  title: 'Picnic Admin Panel',
  description: 'Picnic Admin Panel',
  icons: {
    icon: '/public/app_icon.png',
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
                        accessControlProvider={accessControlProvider}
                        resources={[
                          // 기존 메뉴들
                          {
                            name: 'vote',
                            list: '/vote',
                            create: '/vote/create',
                            edit: '/vote/edit/:id',
                            show: '/vote/show/:id',
                            meta: {
                              label: '투표 관리',
                              icon: <CheckCircleOutlined />,
                              list: {
                                label: '투표 목록',
                              },
                              create: {
                                label: '투표 생성',
                              },
                              edit: {
                                label: '투표 수정',
                              },
                              show: {
                                label: '투표 조회',
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
                              label: '미디어 관리',
                              icon: <VideoCameraOutlined />,
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
                              label: '아티스트 그룹 관리',
                              icon: <GroupOutlined />,
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
                              label: '아티스트 관리',
                              icon: <UserOutlined />,
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
                          {
                            name: 'config',
                            list: '/config',
                            create: '/config/create',
                            edit: '/config/edit/:id',
                            show: '/config/show/:id',
                            meta: {
                              label: '설정 관리',
                              icon: <SettingOutlined />,
                              list: {
                                label: '설정 목록',
                              },
                              create: {
                                label: '설정 추가',
                              },
                              edit: {
                                label: '설정 수정',
                              },
                              show: {
                                label: '설정 상세',
                              },
                            },
                          },
                          // 관리 메뉴 (권한 관리 상위 메뉴) - 가장 아래로 이동
                          {
                            name: 'admin',
                            meta: {
                              label: '관리자 설정',
                              icon: <SettingOutlined />,
                            },
                          },
                          // 권한 관리 리소스들 (경로 수정)
                          {
                            name: 'admin_roles',
                            list: '/admin_roles', // 경로 수정
                            create: '/admin_roles/create', // 경로 수정
                            edit: '/admin_roles/edit/:id', // 경로 수정
                            show: '/admin_roles/show/:id', // 경로 수정
                            meta: {
                              parent: 'admin',
                              label: '역할 관리',
                              icon: <TeamOutlined />,
                              list: {
                                label: '역할 목록',
                              },
                              create: {
                                label: '역할 추가',
                              },
                              edit: {
                                label: '역할 수정',
                              },
                              show: {
                                label: '역할 상세',
                              },
                            },
                          },
                          {
                            name: 'admin_permissions',
                            list: '/admin_permissions', // 경로 수정
                            create: '/admin_permissions/create', // 경로 수정
                            edit: '/admin_permissions/edit/:id', // 경로 수정
                            show: '/admin_permissions/show/:id', // 경로 수정
                            meta: {
                              parent: 'admin',
                              label: '권한 관리',
                              icon: <KeyOutlined />,
                              list: {
                                label: '권한 목록',
                              },
                              create: {
                                label: '권한 추가',
                              },
                              edit: {
                                label: '권한 수정',
                              },
                              show: {
                                label: '권한 상세',
                              },
                            },
                          },
                          {
                            name: 'admin_role_permissions',
                            list: '/admin_role_permissions', // 경로 수정
                            create: '/admin_role_permissions/create', // 경로 수정
                            edit: '/admin_role_permissions/edit/:id', // 경로 수정
                            show: '/admin_role_permissions/show/:id', // 경로 수정
                            meta: {
                              parent: 'admin',
                              label: '역할-권한 매핑',
                              icon: <LinkOutlined />,
                              list: {
                                label: '역할-권한 목록',
                              },
                              create: {
                                label: '역할-권한 연결',
                              },
                              edit: {
                                label: '역할-권한 수정',
                              },
                              show: {
                                label: '역할-권한 상세',
                              },
                            },
                          },
                          {
                            name: 'admin_user_roles',
                            list: '/admin_user_roles', // 경로 수정
                            create: '/admin_user_roles/create', // 경로 수정
                            edit: '/admin_user_roles/edit/:id', // 경로 수정
                            show: '/admin_user_roles/show/:id', // 경로 수정
                            meta: {
                              parent: 'admin',
                              label: '사용자-역할 매핑',
                              icon: <UserSwitchOutlined />,
                              list: {
                                label: '사용자-역할 매핑 목록',
                              },
                              create: {
                                label: '사용자-역할 매핑 추가',
                              },
                              edit: {
                                label: '사용자-역할 매핑 수정',
                              },
                              show: {
                                label: '사용자-역할 매핑 상세',
                              },
                            },
                          },
                          // 권한 없는 사용자를 위한 리소스 (메뉴 숨김)
                          {
                            name: 'admin_no_access',
                            list: '/admin/no-access',
                            meta: {
                              hide: true, // 메뉴에서 숨김
                            },
                          },
                        ]}
                        options={{
                          syncWithLocation: true,
                          warnWhenUnsavedChanges: true,
                          useNewQueryKeys: true,
                          projectId: 'Uu8KtH-kZkC5Q-8t8wTz',
                        }}
                      >
                        <PermissionLoadingProvider>
                          <PermissionLoader>
                            <MainLayout>{children}</MainLayout>
                          </PermissionLoader>
                        </PermissionLoadingProvider>
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
