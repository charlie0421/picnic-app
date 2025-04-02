'use client';

import { RefineThemes } from '@refinedev/antd';
import { App as AntdApp, ConfigProvider, theme } from 'antd';
import Cookies from 'js-cookie';
import React, {
  type PropsWithChildren,
  createContext,
  useEffect,
  useState,
} from 'react';
import { getThemeColors } from '@/utils/theme';
import { supabaseBrowserClient } from '@/utils/supabase/client';

type ColorModeContextType = {
  mode: string;
  setMode: (mode: string) => void;
};

export const ColorModeContext = createContext<ColorModeContextType>(
  {} as ColorModeContextType,
);

type ColorModeContextProviderProps = {
  defaultMode?: string;
};

export const ColorModeContextProvider: React.FC<
  PropsWithChildren<ColorModeContextProviderProps>
> = ({ children, defaultMode }) => {
  const [isMounted, setIsMounted] = useState(false);
  const [mode, setMode] = useState(defaultMode || 'light');

  useEffect(() => {
    setIsMounted(true);
  }, []);

  useEffect(() => {
    if (isMounted) {
      // 쿠키에서 테마 확인
      const cookieTheme = Cookies.get('theme');
      if (cookieTheme) {
        setMode(cookieTheme);
      }
    }
  }, [isMounted]);

  const setColorMode = () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    Cookies.set('theme', newMode);
  };

  const { darkAlgorithm, defaultAlgorithm } = theme;

  return (
    <ColorModeContext.Provider
      value={{
        setMode: setColorMode,
        mode,
      }}
    >
      <ConfigProvider
        // you can change the theme colors here. example: ...RefineThemes.Magenta,
        theme={{
          ...RefineThemes.Blue,
          token: {
            ...getThemeColors(),
          },
          algorithm: mode === 'light' ? defaultAlgorithm : darkAlgorithm,
        }}
      >
        <AntdApp>{children}</AntdApp>
      </ConfigProvider>
    </ColorModeContext.Provider>
  );
};
