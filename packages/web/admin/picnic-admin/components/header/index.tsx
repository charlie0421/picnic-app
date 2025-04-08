'use client';

import { ColorModeContext } from '@/contexts/color-mode';
import type { RefineThemedLayoutV2HeaderProps } from '@refinedev/antd';
import { useGetIdentity, useLogout, useIsAuthenticated } from '@refinedev/core';
import {
  Layout as AntdLayout,
  Avatar,
  Space,
  Switch,
  theme,
  Typography,
  Button,
} from 'antd';
import React, { useContext } from 'react';

const { Text } = Typography;
const { useToken } = theme;

type IUser = {
  id: number;
  name: string;
  avatar: string;
  email: string;
};

export const Header: React.FC<RefineThemedLayoutV2HeaderProps> = ({
  sticky = true,
}) => {
  const { token } = useToken();
  const { data: user } = useGetIdentity<IUser>();
  const { mutate: logout } = useLogout();
  const { mode, setMode } = useContext(ColorModeContext);
  const { data: isAuthenticated } = useIsAuthenticated();

  const headerStyles: React.CSSProperties = {
    backgroundColor: token.colorBgElevated,
    display: 'flex',
    justifyContent: 'flex-end',
    alignItems: 'center',
    padding: '0px 24px',
    height: '64px',
  };

  if (sticky) {
    headerStyles.position = 'sticky';
    headerStyles.top = 0;
    headerStyles.zIndex = 1;
  }

  return (
    <AntdLayout.Header style={headerStyles}>
      <Space>
        <Switch
          checkedChildren='🌛'
          unCheckedChildren='🔆'
          onChange={() => setMode(mode === 'light' ? 'dark' : 'light')}
          defaultChecked={mode === 'dark'}
        />
        {isAuthenticated && user && (
          <Space style={{ marginLeft: '8px' }} size='middle'>
            {user.email && <Text strong>{user.email}</Text>}
            {user.avatar && <Avatar src={user.avatar} alt={user.name} />}
          </Space>
        )}
      </Space>
    </AntdLayout.Header>
  );
};
