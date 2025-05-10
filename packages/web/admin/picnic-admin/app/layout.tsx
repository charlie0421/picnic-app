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
import { PermissionLoader } from '@/components/auth/PermissionLoader';
import { PermissionLoadingProvider } from '@/contexts/PermissionLoadingContext';
import MainLayout from '@/components/layout/MainLayout';
import ActivityLogger from './components/logger/ActivityLogger';
import { ResourceType } from '@/lib/services/activityLogger';

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
  PictureOutlined,
  BarChartOutlined,
  GiftOutlined,
  AppstoreOutlined,
  UsergroupAddOutlined,
  StarOutlined,
  FileTextOutlined,
  ReadOutlined,
  CommentOutlined,
  CustomerServiceOutlined,
  SolutionOutlined,
  QuestionCircleOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import Image from 'next/image';
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
                          // 대시보드 추가
                          {
                            name: 'dashboard',
                            list: '/dashboard',
                            meta: {
                              label: '대시보드',
                              icon: <AppstoreOutlined />,
                              resourceType: ResourceType.DASHBOARD,
                            },
                          },
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
                              resourceType: ResourceType.VOTE,
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
                            name: 'banner',
                            list: '/banner',
                            create: '/banner/create',
                            edit: '/banner/edit/:id',
                            show: '/banner/show/:id',
                            meta: {
                              label: '배너 관리',
                              icon: <PictureOutlined />,
                              resourceType: ResourceType.BANNER,
                              list: {
                                label: '배너 목록',
                              },
                              create: {
                                label: '배너 추가',
                              },
                              edit: {
                                label: '배너 수정',
                              },
                              show: {
                                label: '배너 상세',
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
                              resourceType: ResourceType.MEDIA,
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
                            name: 'user_profiles',
                            list: '/user_profiles',
                            create: '/user_profiles/create',
                            edit: '/user_profiles/edit/:id',
                            show: '/user_profiles/show/:id',
                            meta: {
                              label: '유저 관리',
                              icon: <UserOutlined />,
                              resourceType: ResourceType.USER,
                              list: {
                                label: '유저 목록',
                              },
                              create: {
                                label: '유저 추가',
                              },
                              edit: {
                                label: '유저 수정',
                              },
                              show: {
                                label: '유저 상세',
                              },
                            },
                          },
                          {
                            name: 'reward',
                            list: '/reward',
                            create: '/reward/create',
                            edit: '/reward/edit/:id',
                            show: '/reward/show/:id',
                            meta: {
                              label: '리워드 관리',
                              icon: <GiftOutlined />,
                              resourceType: ResourceType.REWARD,
                              list: {
                                label: '리워드 목록',
                              },
                              create: {
                                label: '리워드 추가',
                              },
                              edit: {
                                label: '리워드 수정',
                              },
                              show: {
                                label: '리워드 상세',
                              },
                            },
                          },
                          // 고객 관리 메뉴 그룹 추가
                          {
                            name: 'customerGroup',
                            meta: {
                              label: 'CS 관리',
                              icon: <CustomerServiceOutlined />,
                              resourceType: ResourceType.CUSTOMER_GROUP,
                            },
                          },
                          {
                            name: 'notices',
                            list: '/notices',
                            create: '/notices/create',
                            edit: '/notices/edit/:id',
                            show: '/notices/show/:id',
                            meta: {
                              parent: 'customerGroup',
                              label: '공지사항',
                              icon: <NotificationOutlined />,
                              resourceType: ResourceType.NOTICE,
                              list: {
                                label: '공지사항 목록',
                              },
                              create: {
                                label: '공지사항 작성',
                              },
                              edit: {
                                label: '공지사항 수정',
                              },
                              show: {
                                label: '공지사항 상세',
                              },
                              idField: 'notice_id',
                            },
                          },
                          {
                            name: 'faqs',
                            list: '/faqs',
                            create: '/faqs/create',
                            edit: '/faqs/edit/:id',
                            show: '/faqs/show/:id',
                            meta: {
                              parent: 'customerGroup',
                              label: 'FAQ',
                              icon: <SolutionOutlined />,
                              resourceType: ResourceType.FAQ,
                              list: {
                                label: 'FAQ 목록',
                              },
                              create: {
                                label: 'FAQ 작성',
                              },
                              edit: {
                                label: 'FAQ 수정',
                              },
                              show: {
                                label: 'FAQ 상세',
                              },
                              idField: 'faq_id',
                            },
                          },
                          {
                            name: 'qnas',
                            list: '/qnas',
                            create: '/qnas/create',
                            edit: '/qnas/edit/:id',
                            show: '/qnas/show/:id',
                            meta: {
                              parent: 'customerGroup',
                              label: 'Q&A',
                              icon: <QuestionCircleOutlined />,
                              resourceType: ResourceType.QNA,
                              list: {
                                label: 'Q&A 목록',
                              },
                              create: {
                                label: '질문 작성',
                              },
                              edit: {
                                label: '질문 수정/답변',
                              },
                              show: {
                                label: '질문 상세',
                              },
                              idField: 'qna_id',
                            },
                          },
                          // 커뮤니티 관리 메뉴 그룹 추가
                          {
                            name: 'communityGroup',
                            meta: {
                              label: '커뮤니티 관리',
                              icon: <CommentOutlined />,
                              resourceType: ResourceType.COMMUNITY_GROUP,
                            },
                          },
                          {
                            name: 'boards',
                            list: '/boards',
                            create: '/boards/create',
                            edit: '/boards/edit/:id',
                            show: '/boards/show/:id',
                            meta: {
                              parent: 'communityGroup',
                              label: '게시판 관리',
                              icon: <ReadOutlined />,
                              resourceType: ResourceType.BOARD,
                              list: {
                                label: '게시판 목록',
                              },
                              create: {
                                label: '게시판 생성',
                              },
                              edit: {
                                label: '게시판 수정',
                              },
                              show: {
                                label: '게시판 상세',
                              },
                              idField: 'board_id',
                            },
                          },
                          {
                            name: 'posts',
                            list: '/posts',
                            create: '/posts/create',
                            edit: '/posts/edit/:id',
                            show: '/posts/show/:id',
                            meta: {
                              parent: 'communityGroup',
                              label: '게시글 관리',
                              icon: <FileTextOutlined />,
                              resourceType: ResourceType.POST,
                              list: {
                                label: '게시글 목록',
                              },
                              create: {
                                label: '게시글 생성',
                              },
                              edit: {
                                label: '게시글 수정',
                              },
                              show: {
                                label: '게시글 상세',
                              },
                              idField: 'post_id',
                            },
                          },
                          // 아티스트 관련 메뉴 그룹 추가
                          {
                            name: 'artistGroup',
                            meta: {
                              label: '아티스트 관리',
                              icon: <StarOutlined />,
                              resourceType: ResourceType.ARTIST_GROUP,
                            },
                          },
                          {
                            name: 'artist',
                            list: '/artist',
                            create: '/artist/create',
                            edit: '/artist/edit/:id',
                            show: '/artist/show/:id',
                            meta: {
                              parent: 'artistGroup',
                              label: '아티스트',
                              icon: <StarOutlined />,
                              resourceType: ResourceType.ARTIST,
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
                            name: 'artist_group',
                            list: '/artist-group',
                            create: '/artist-group/create',
                            edit: '/artist-group/edit/:id',
                            show: '/artist-group/show/:id',
                            meta: {
                              parent: 'artistGroup',
                              label: '아티스트 그룹',
                              icon: <UsergroupAddOutlined />,
                              resourceType: ResourceType.ARTIST_GROUP,
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
                          // 통계
                          {
                            name: 'statisticsGroup',
                            meta: {
                              label: '통계 관리',
                              icon: <BarChartOutlined />,
                              canCreate: true,
                              canEdit: true,
                              canDelete: true,
                              canShow: true,
                              resourceType: ResourceType.STATISTICS_GROUP,
                            },
                          },
                          {
                            name: 'statistics_ads',
                            list: '/statistics/ads',
                            meta: {
                              parent: 'statisticsGroup',
                              label: '광고 통계',
                              icon: <BarChartOutlined />,
                              canCreate: true,
                              canEdit: true,
                              canDelete: true,
                              canShow: true,
                              resourceType: ResourceType.STATISTICS_ADS,
                            },
                          },
                          {
                            name: 'receipts',
                            list: '/statistics/receipts',
                            meta: {
                              parent: 'statisticsGroup',
                              label: '영수증 통계',
                              icon: <BarChartOutlined />,
                              canCreate: true,
                              canEdit: true,
                              canDelete: true,
                              canShow: true,
                              resourceType: ResourceType.RECEIPTS,
                            },
                          },
                          // 앱 설정
                          {
                            name: 'config',
                            list: '/config',
                            create: '/config/create',
                            edit: '/config/edit/:id',
                            show: '/config/show/:id',
                            meta: {
                              label: '앱 설정 관리',
                              icon: <AppstoreOutlined />,
                              resourceType: ResourceType.CONFIG,
                              list: {
                                label: '앱 설정 목록',
                              },
                              create: {
                                label: '앱 설정 추가',
                              },
                              edit: {
                                label: '앱 설정 수정',
                              },
                              show: {
                                label: '앱 설정 상세',
                              },
                            },
                          },
                          // 앱 버전
                          {
                            name: 'version',
                            list: '/version',
                            show: '/version/show/:id',
                            edit: '/version/edit/:id',
                            meta: {
                              label: '앱 버전 관리',
                              icon: <AppstoreOutlined />,
                              resourceType: ResourceType.APP_VERSION,
                              list: {
                                label: '앱 버전 목록',
                              },
                              show: {
                                label: '앱 버전 상세',
                              },
                              edit: {
                                label: '앱 버전 수정',
                              },
                            },
                          },
                          // 관리 메뉴 (권한 관리 상위 메뉴) - 가장 아래로 이동
                          {
                            name: 'admin',
                            meta: {
                              label: '관리자 설정',
                              icon: <SettingOutlined />,
                              resourceType: ResourceType.ADMIN,
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
                              resourceType: ResourceType.ADMIN_ROLES,
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
                              resourceType: ResourceType.ADMIN_PERMISSIONS,
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
                              resourceType: ResourceType.ADMIN_ROLE_PERMISSIONS,
                              list: {
                                label: '역할-권한 목록',
                              },
                              create: {
                                label: '역할-권한 추가',
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
                              resourceType: ResourceType.ADMIN_USER_ROLES,
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
                              resourceType: ResourceType.ADMIN_NO_ACCESS,
                            },
                          },
                          // 활동 로그 메뉴 추가
                          {
                            name: 'activities',
                            list: '/activities',
                            meta: {
                              label: '활동 로그',
                              icon: <FileTextOutlined />,
                              parent: 'admin', // 관리자 설정 아래에 포함
                              resourceType: ResourceType.ACTIVITIES,
                            },
                          },
                        ]}
                        options={{
                          syncWithLocation: true,
                          warnWhenUnsavedChanges: true,
                          useNewQueryKeys: true,
                          projectId: 'Uu8KtH-kZkC5Q-8t8wTz',
                          title: {
                            icon: <div>
                              <Image src="/app_icon.png" alt="Picnic Admin Panel" width={25} height={25} />
                            </div>,
                            text: 'Picnic Admin Panel',
                          },
                        }}
                      >
                        <PermissionLoadingProvider>
                          <PermissionLoader>
                            <MainLayout>
                              <ActivityLogger />
                              {children}
                            </MainLayout>
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
