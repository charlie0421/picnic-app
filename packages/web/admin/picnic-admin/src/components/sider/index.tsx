'use client';

import React, { useState } from 'react';
import {
  CanAccess,
  ITreeMenu,
  useIsExistAuthentication,
  useLogout,
  useTitle,
  useTranslate,
  useRouterContext,
  useRouterType,
  useLink,
  useMenu,
  useRefineContext,
  useActiveAuthProvider,
} from '@refinedev/core';
import {
  ThemedTitleV2 as DefaultTitle,
  useThemedLayoutContext,
} from '@refinedev/antd';
import {
  DashboardOutlined,
  LogoutOutlined,
  UnorderedListOutlined,
  BarsOutlined,
  LeftOutlined,
  RightOutlined,
} from '@ant-design/icons';
import { Layout, Menu, Grid, Drawer, Button, theme } from 'antd';
import { RefineLayoutSiderProps } from '@refinedev/antd';
import { COLORS } from '@utils/theme';
import Image from 'next/image';

const { SubMenu } = Menu;
const { useToken } = theme;

// 커스텀 타이틀 컴포넌트 정의
const CustomTitle = ({ collapsed }: { collapsed: boolean }) => {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: collapsed ? 'center' : 'flex-start',
        gap: '12px',
      }}
    >
      <Image
        src='/icons/app_icon.png'
        alt='Picnic Admin'
        width={28}
        height={28}
      />
      {!collapsed && (
        <div
          style={{
            fontSize: '18px',
            fontWeight: 'bold',
            color: COLORS.primary,
          }}
        >
          Picnic Admin
        </div>
      )}
    </div>
  );
};

export const Sider: React.FC<RefineLayoutSiderProps> = ({
  Title: TitleFromProps,
  render,
  meta,
}) => {
  const { token } = useToken();
  const [collapsed, setCollapsed] = useState<boolean>(false);
  const [drawerOpen, setDrawerOpen] = useState<boolean>(false);
  const isExistAuthentication = useIsExistAuthentication();
  const t = useTranslate();
  const { Link } = useLink();
  const { menuItems, selectedKey, defaultOpenKeys } = useMenu({ meta });
  const breakpoint = Grid.useBreakpoint();
  const { hasDashboard } = useRefineContext();
  const routerType = useRouterType();
  const { warnWhen, setWarnWhen } = useRefineContext();
  const { Title: TitleFromContext } = useThemedLayoutContext();
  const authProvider = useActiveAuthProvider();
  const { mutate: mutateLogout } = useLogout({
    v3LegacyAuthProviderCompatible: Boolean(authProvider?.isLegacy),
  });
  const { push } = useRouterContext();
  const Title = TitleFromProps ?? TitleFromContext ?? CustomTitle;

  const isMobile =
    typeof breakpoint.lg === 'undefined' ? false : !breakpoint.lg;

  const renderTreeView = (tree: ITreeMenu[], selectedKey?: string) => {
    return tree.map((item) => {
      const { icon, label, route, name, children, parentName, meta, options } =
        item;

      if (children.length > 0) {
        return (
          <CanAccess
            key={item.key}
            resource={name.toLowerCase()}
            action='list'
            params={{
              resource: item,
            }}
          >
            <SubMenu
              key={item.key}
              icon={icon ?? <UnorderedListOutlined />}
              title={label}
            >
              {renderTreeView(children, selectedKey)}
            </SubMenu>
          </CanAccess>
        );
      }
      const isSelected = item.key === selectedKey;
      const isRoute = !(
        routerType === 'legacy' && !(route === '/' || route === '')
      );

      // Convert treeview menu items to Menu items
      return (
        <CanAccess
          key={item.key}
          resource={name.toLowerCase()}
          action='list'
          params={{
            resource: item,
          }}
        >
          <Menu.Item
            key={item.key}
            icon={icon ?? (isRoute && <UnorderedListOutlined />)}
            style={{
              fontWeight: isSelected ? 'bold' : 'normal',
            }}
            onClick={() => {
              if (item.key === selectedKey) return;

              if (warnWhen) {
                const confirm = window.confirm(
                  t(
                    'warnWhenUnsavedChanges',
                    'Are you sure you want to leave? You have unsaved changes.',
                  ),
                );

                if (confirm) {
                  setWarnWhen(false);
                  push(route ?? '');
                }
              } else {
                push(route ?? '');
              }
            }}
          >
            {label}
          </Menu.Item>
        </CanAccess>
      );
    });
  };

  // Convert the tree view items to Ant Design Menu items format
  const generateMenuItems = () => {
    const items = menuItems.map((item, index) => {
      const { icon, label, route, name, children, parentName, meta, options } =
        item;

      if (children.length > 0) {
        return {
          key: item.key,
          icon: icon ?? <UnorderedListOutlined />,
          label: label,
          children: generateChildMenuItems(children, selectedKey),
        };
      }

      const isSelected = item.key === selectedKey;
      const isRoute = !(
        routerType === 'legacy' && !(route === '/' || route === '')
      );

      return {
        key: item.key,
        icon: icon ?? (isRoute && <UnorderedListOutlined />),
        label: label,
        style: {
          fontWeight: isSelected ? 'bold' : 'normal',
        },
        onClick: () => {
          if (item.key === selectedKey) return;

          if (warnWhen) {
            const confirm = window.confirm(
              t(
                'warnWhenUnsavedChanges',
                'Are you sure you want to leave? You have unsaved changes.',
              ),
            );

            if (confirm) {
              setWarnWhen(false);
              push(route ?? '');
            }
          } else {
            push(route ?? '');
          }
        },
      };
    });

    // Add dashboard menu item
    if (hasDashboard) {
      items.unshift({
        key: '/',
        icon: <DashboardOutlined />,
        label: t('dashboard.title', 'Dashboard'),
        style: {
          fontWeight: 'normal',
        },
        onClick: () => {
          push('/');
        },
      });
    }

    // Add logout menu item
    if (isExistAuthentication) {
      items.push({
        key: 'logout',
        icon: <LogoutOutlined />,
        label: t('buttons.logout', 'Logout'),
        style: {
          fontWeight: 'normal',
        },
        onClick: () => {
          mutateLogout();
        },
      });
    }

    return items;
  };

  // Helper function to generate children menu items recursively
  const generateChildMenuItems = (
    children: ITreeMenu[],
    selectedKey?: string,
  ) => {
    return children.map((item) => {
      if (item.children.length > 0) {
        return {
          key: item.key,
          icon: item.icon ?? <UnorderedListOutlined />,
          label: item.label,
          children: generateChildMenuItems(item.children, selectedKey),
        };
      }

      const isSelected = item.key === selectedKey;
      const isRoute = !(
        routerType === 'legacy' && !(item.route === '/' || item.route === '')
      );

      return {
        key: item.key,
        icon: item.icon ?? (isRoute && <UnorderedListOutlined />),
        label: item.label,
        style: {
          fontWeight: isSelected ? 'bold' : 'normal',
        },
        onClick: () => {
          if (item.key === selectedKey) return;

          if (warnWhen) {
            const confirm = window.confirm(
              t(
                'warnWhenUnsavedChanges',
                'Are you sure you want to leave? You have unsaved changes.',
              ),
            );

            if (confirm) {
              setWarnWhen(false);
              push(item.route ?? '');
            }
          } else {
            push(item.route ?? '');
          }
        },
      };
    });
  };

  const items = generateMenuItems();

  const renderSider = () => {
    if (render) {
      return render({
        dashboard: hasDashboard,
        collapsed,
        menu: renderTreeView(menuItems, selectedKey),
        items: items,
      });
    }
    return (
      <>
        <Button
          type='text'
          style={{
            borderRadius: 0,
            width: '100%',
            backgroundColor: token.colorBgContainer,
            color: token.colorPrimaryTextHover,
            height: '40px',
          }}
          onClick={() => setCollapsed((prev) => !prev)}
        >
          {collapsed ? (
            <RightOutlined
              style={{
                color: token.colorPrimaryTextActive,
              }}
            />
          ) : (
            <LeftOutlined
              style={{
                color: token.colorPrimaryTextActive,
              }}
            />
          )}
        </Button>
        <Menu
          defaultOpenKeys={defaultOpenKeys}
          selectedKeys={[selectedKey]}
          mode='inline'
          style={{
            border: 'none',
            paddingTop: '8px',
            backgroundColor: token.colorBgContainer,
          }}
          items={items}
        />
      </>
    );
  };

  const renderMenu = () => {
    return (
      <>
        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '64px',
            backgroundColor: token.colorBgContainer,
            paddingLeft: collapsed ? '0px' : '16px',
          }}
        >
          <Title collapsed={collapsed} />
        </div>
        {renderSider()}
      </>
    );
  };

  const renderDrawerSider = () => {
    return (
      <>
        <Drawer
          open={drawerOpen}
          onClose={() => setDrawerOpen(false)}
          placement='left'
          closable={false}
          width={200}
          bodyStyle={{
            padding: 0,
          }}
          maskClosable={true}
        >
          <Layout
            style={{
              height: '100%',
              backgroundColor: token.colorBgContainer,
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '64px',
                backgroundColor: token.colorBgContainer,
                paddingLeft: '16px',
              }}
            >
              <Title collapsed={false} />
            </div>
            <Menu
              defaultOpenKeys={defaultOpenKeys}
              selectedKeys={[selectedKey]}
              mode='inline'
              style={{
                border: 'none',
                backgroundColor: token.colorBgContainer,
              }}
              items={items}
              onClick={() => {
                setDrawerOpen(false);
              }}
            />
          </Layout>
        </Drawer>
        <Button
          style={{
            borderRadius: 0,
            width: '100%',
            backgroundColor: token.colorBgContainer,
            color: token.colorPrimaryTextHover,
            height: '40px',
          }}
          onClick={() => setDrawerOpen(true)}
        >
          <BarsOutlined />
        </Button>
      </>
    );
  };

  if (isMobile) {
    return (
      <Layout.Sider
        style={{
          backgroundColor: token.colorBgElevated,
          borderRight: `1px solid ${token.colorBorderBg}`,
        }}
        width={200}
        collapsedWidth={80}
        trigger={null}
        collapsed={true}
        breakpoint='lg'
        theme='light'
      >
        {renderDrawerSider()}
      </Layout.Sider>
    );
  }

  return (
    <Layout.Sider
      style={{
        backgroundColor: token.colorBgContainer,
        borderRight: `1px solid ${token.colorBorderBg}`,
      }}
      collapsible
      collapsed={collapsed}
      onCollapse={(collapsed) => setCollapsed(collapsed)}
      width={200}
      collapsedWidth={80}
      breakpoint='lg'
      theme='light'
    >
      {renderMenu()}
    </Layout.Sider>
  );
};
