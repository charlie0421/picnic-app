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

    // 로컬 스토리지의 사용자 관련 정보 정리
    localStorage.removeItem('user-info');
    localStorage.removeItem('user-roles');
    localStorage.removeItem('role-permissions');
    localStorage.removeItem('permissions');
    localStorage.removeItem('permissions-map');

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

    const permissions = await getPermissionsWithLogging(user.id);

    // 권한 정보를 로컬 스토리지에 저장 (제거)
    // if (permissions) {
    //   localStorage.setItem('permissions-map', JSON.stringify(permissions));
    // }

    return permissions;
  },
  getIdentity: async () => {
    logAuth('*** getIdentity 함수 호출됨 ***');
    const { data } = await supabaseBrowserClient.auth.getUser();

    if (data?.user) {
      logAuth('getIdentity: 사용자 정보 가져오기 시작', {
        userId: data.user.id,
      });
      // 사용자의 추가 정보 조회 (슈퍼관리자 여부 등)
      const { data: userData, error } = await supabaseBrowserClient
        .from('user_profiles')
        .select('*')
        .eq('id', data.user.id)
        .single();

      if (error) {
        logAuth(
          'getIdentity: 사용자 프로필 조회 실패',
          { userId: data.user.id, error: error.message },
          LogLevel.ERROR,
        );
        console.error('사용자 정보 조회 실패:', error);
        // 기본 정보라도 반환
        return {
          id: data.user.id,
          email: data.user.email,
          name: data.user.email, // 이름 정보가 없을 경우 이메일 사용
        };
      }
      logAuth('getIdentity: 사용자 프로필 조회 성공', {
        userId: data.user.id,
        userData,
      });

      // 사용자 정보 구성 (isSuperAdmin 제거)
      const userInfo = {
        id: data.user.id,
        email: data.user.email,
        name:
          userData?.nickname ||
          userData?.display_name ||
          userData?.name ||
          data.user.email,
        // isSuperAdmin: userData?.is_admin || false, // is_admin 정보 제거
      };

      // userInfo 객체 로그 추가
      logAuth('getIdentity: 구성된 userInfo 객체', { userInfo });

      // 로컬 스토리지 저장 로직 제거 (user-info 제외)
      // localStorage.setItem('user-info', JSON.stringify(userInfo));
      // logAuth('getIdentity: user-info 저장 완료', { userInfo });

      // 사용자 역할 정보 조회 (제거)
      // const { data: userRoles } = await supabaseBrowserClient
      //   .from('admin_user_roles')
      //   .select('*')
      //   .eq('user_id', data.user.id);

      // if (userRoles) {
      //   localStorage.setItem('user-roles', JSON.stringify(userRoles));
      //   logAuth('getIdentity: user-roles 저장 완료', { userRoles });
      // } else {
      //   logAuth(
      //     'getIdentity: user-roles 정보 없음',
      //     { userId: data.user.id },
      //     LogLevel.WARN,
      //   );
      // }

      // 역할-권한 관계 정보 조회 (제거)
      // const { data: rolePermissions } = await supabaseBrowserClient
      //   .from('admin_role_permissions')
      //   .select('*');

      // if (rolePermissions) {
      //   localStorage.setItem(
      //     'role-permissions',
      //     JSON.stringify(rolePermissions),
      //   );
      //   logAuth('getIdentity: role-permissions 저장 완료', {
      //     rolePermissionsCount: rolePermissions.length,
      //   });
      // } else {
      //   logAuth('getIdentity: role-permissions 정보 없음', {}, LogLevel.WARN);
      // }

      // 권한 정보 조회 (제거)
      // const { data: permissions } = await supabaseBrowserClient
      //   .from('admin_permissions')
      //   .select('*');

      // if (permissions) {
      //   localStorage.setItem('permissions', JSON.stringify(permissions));
      //   logAuth('getIdentity: permissions 저장 완료', {
      //     permissionsCount: permissions.length,
      //   });
      // } else {
      //   logAuth('getIdentity: permissions 정보 없음', {}, LogLevel.WARN);
      // }

      logAuth('getIdentity: 사용자 식별 정보 반환', {
        userId: data.user.id,
        userInfo,
      });
      return {
        ...data.user, // Supabase 기본 user 정보 포함
        ...userInfo, // user_profiles 정보 포함 (name, isSuperAdmin 등)
      };
    }

    logAuth('getIdentity: 사용자 정보 없음', {}, LogLevel.WARN);
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
    .from('admin_user_roles')
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
    .from('admin_role_permissions')
    .select('admin_permissions!inner(*)')
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
      const { resource, action } = curr.admin_permissions;
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
