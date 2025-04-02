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
      // 먼저 쿠키에서 테마 확인
      const cookieTheme = Cookies.get('theme');

      // 로그인된 사용자인지 확인하고 데이터베이스에서 테마 설정 가져오기
      const fetchUserTheme = async () => {
        try {
          const { data: userData } = await supabaseBrowserClient.auth.getUser();

          if (userData?.user) {
            // 사용자별 테마 설정을 데이터베이스에서 가져오기
            const { data: userPreferences } = await supabaseBrowserClient
              .from('user_preferences')
              .select('theme')
              .eq('user_id', userData.user.id)
              .single();

            if (userPreferences?.theme) {
              // DB에 저장된 테마 우선 적용
              setMode(userPreferences.theme);
              // 쿠키도 동기화
              Cookies.set('theme', userPreferences.theme);
              return;
            }
          }

          // DB에 설정이 없거나 로그인하지 않은 경우 쿠키 사용
          if (cookieTheme) {
            setMode(cookieTheme);
          }
        } catch (error) {
          console.error('테마 설정 가져오기 실패:', error);
          // 오류 발생 시 쿠키 사용
          if (cookieTheme) {
            setMode(cookieTheme);
          }
        }
      };

      fetchUserTheme();
    }
  }, [isMounted]);

  const setColorMode = async () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    Cookies.set('theme', newMode);

    try {
      // 로그인된 사용자인 경우 DB에도 저장
      const { data: userData } = await supabaseBrowserClient.auth.getUser();
      if (userData?.user) {
        const { error } = await supabaseBrowserClient
          .from('user_preferences')
          .upsert(
            {
              user_id: userData.user.id,
              theme: newMode,
              updated_at: new Date().toISOString(),
            },
            {
              onConflict: 'user_id',
              ignoreDuplicates: false,
            },
          );

        if (error) {
          console.error('테마 설정 저장 실패:', error);
        }
      }
    } catch (error) {
      console.error('테마 설정 저장 중 오류 발생:', error);
    }
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
