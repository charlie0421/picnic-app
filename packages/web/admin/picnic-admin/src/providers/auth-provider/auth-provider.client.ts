'use client';

import type { AuthProvider } from '@refinedev/core';
import { supabaseBrowserClient } from '@utils/supabase/client';
import { logAuth, logPermission, LogLevel } from '@/utils/logger';

export const authProviderClient: AuthProvider = {
  login: async ({ email, password }) => {
    // 로그인 시도 로깅
    logAuth('로그인 시도', { email });

    const { data, error } = await supabaseBrowserClient.auth.signInWithPassword(
      {
        email,
        password,
      },
    );

    if (error) {
      // 로그인 실패 로깅
      logAuth('로그인 실패', { email, error: error.message }, LogLevel.ERROR);
      return {
        success: false,
        error,
      };
    }

    if (data?.session) {
      await supabaseBrowserClient.auth.setSession(data.session);

      // 로그인 성공 로깅
      logAuth('로그인 성공', {
        email,
        userId: data.user?.id,
        role: data.user?.role,
      });

      // 권한 정보 가져와서 로깅
      try {
        const permissions = await getPermissionsWithLogging(data.user?.id);

        // 권한 정보 로깅
        logPermission('사용자 권한 로드', {
          userId: data.user?.id,
          permissions,
        });
      } catch (permError) {
        // 권한 정보 로드 실패 로깅
        logPermission(
          '권한 정보 로드 실패',
          { userId: data.user?.id, error: permError },
          LogLevel.ERROR,
        );
      }

      return {
        success: true,
        redirectTo: '/',
      };
    }

    // for third-party login
    logAuth('로그인 실패 (세션 없음)', { email }, LogLevel.ERROR);
    return {
      success: false,
      error: {
        name: 'LoginError',
        message: 'Invalid username or password',
      },
    };
  },
  logout: async () => {
    // 로그아웃 전 사용자 정보 가져오기
    const { data: userData } = await supabaseBrowserClient.auth.getUser();

    const { error } = await supabaseBrowserClient.auth.signOut();

    if (error) {
      // 로그아웃 실패 로깅
      logAuth(
        '로그아웃 실패',
        {
          userId: userData?.user?.id,
          error: error.message,
        },
        LogLevel.ERROR,
      );

      return {
        success: false,
        error,
      };
    }

    // 로그아웃 성공 로깅
    logAuth('로그아웃 성공', { userId: userData?.user?.id });

    return {
      success: true,
      redirectTo: '/login',
    };
  },
  check: async () => {
    const { data, error } = await supabaseBrowserClient.auth.getUser();
    const { user } = data;

    if (error) {
      return {
        authenticated: false,
        redirectTo: '/login',
        logout: true,
      };
    }

    if (user) {
      return {
        authenticated: true,
      };
    }

    return {
      authenticated: false,
      redirectTo: '/login',
    };
  },
  getPermissions: async () => {
    const {
      data: { user },
    } = await supabaseBrowserClient.auth.getUser();

    if (!user) return null;

    return getPermissionsWithLogging(user.id);
  },
  getIdentity: async () => {
    const { data } = await supabaseBrowserClient.auth.getUser();

    if (data?.user) {
      return {
        ...data.user,
        name: data.user.email,
      };
    }

    return null;
  },
  onError: async (error) => {
    if (error?.code === 'PGRST301' || error?.code === 401) {
      return {
        logout: true,
      };
    }

    return { error };
  },
};

/**
 * 사용자 권한 정보를 가져오고 로깅하는 유틸리티 함수
 * @param userId 사용자 ID
 * @returns 권한 정보 객체
 */
const getPermissionsWithLogging = async (userId: string | undefined) => {
  if (!userId) {
    logPermission('권한 조회 실패: 사용자 ID 없음', {}, LogLevel.ERROR);
    return null;
  }

  // 사용자의 역할과 권한을 가져옵니다
  const { data: userRoles, error: roleError } = await supabaseBrowserClient
    .from('user_roles')
    .select('role_id')
    .eq('user_id', userId);

  if (roleError) {
    logPermission(
      '사용자 역할 조회 실패',
      {
        userId,
        error: roleError.message,
      },
      LogLevel.ERROR,
    );
    return null;
  }

  if (!userRoles?.length) {
    logPermission('사용자에게 할당된 역할 없음', { userId }, LogLevel.WARN);
    return null;
  }

  // 역할 ID 로깅
  const roleIds = userRoles.map((ur) => ur.role_id);
  logPermission('사용자 역할 조회 성공', { userId, roleIds });

  const { data: permissions, error: permError } = await supabaseBrowserClient
    .from('role_permissions')
    .select('permissions!inner(*)')
    .in('role_id', roleIds);

  if (permError) {
    logPermission(
      '권한 정보 조회 실패',
      {
        userId,
        roleIds,
        error: permError.message,
      },
      LogLevel.ERROR,
    );
    return null;
  }

  if (!permissions?.length) {
    logPermission(
      '역할에 할당된 권한 없음',
      { userId, roleIds },
      LogLevel.WARN,
    );
    return null;
  }

  // 권한을 { resource: [actions] } 형태로 변환
  const permissionsMap = permissions.reduce(
    (acc: Record<string, string[]>, curr: any) => {
      const { resource, action } = curr.permissions;
      if (!acc[resource]) {
        acc[resource] = [];
      }
      if (!acc[resource].includes(action)) {
        acc[resource].push(action);
      }
      return acc;
    },
    {},
  );

  // 최종 권한 맵 로깅
  logPermission('사용자 권한 맵 생성 완료', {
    userId,
    permissionsCount: permissions.length,
    permissionsMap,
  });

  return permissionsMap;
};
