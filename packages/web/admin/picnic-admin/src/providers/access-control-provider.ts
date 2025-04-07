'use client';

import { AccessControlProvider } from '@refinedev/core';
import { authProviderClient } from './auth-provider/auth-provider.client';
import { logPermission, LogLevel } from '@/utils/logger';

// 사용자 식별 정보를 위한 인터페이스 정의
interface UserIdentity {
  id?: string;
  email?: string;
  name?: string;
  [key: string]: any;
}

export const accessControlProvider: AccessControlProvider = {
  can: async ({ resource, action, params }) => {
    // 로그인하지 않은 사용자는 접근 불가
    const { authenticated, error } = (await authProviderClient.check?.()) || {};

    if (!authenticated) {
      logPermission(
        '인증되지 않은 사용자의 접근 시도',
        { resource, action, error },
        LogLevel.WARN,
      );
      return { can: false, reason: 'Unauthorized' };
    }

    // 사용자 식별 정보 가져오기
    const userIdentity =
      (await authProviderClient.getIdentity?.()) as UserIdentity | null;

    // 사용자의 권한 가져오기
    const permissions = await authProviderClient.getPermissions?.();

    // 리소스에 대한 접근 권한 확인 및 로깅
    const userId = userIdentity?.id;
    const userEmail = userIdentity?.email;
    const resourceKey = resource as string;

    // permissions가 Record<string, string[]> 형태라고 가정
    if (permissions && typeof permissions === 'object' && resourceKey) {
      const resourcePermissions = (permissions as Record<string, string[]>)[
        resourceKey
      ];

      if (
        Array.isArray(resourcePermissions) &&
        resourcePermissions.includes(action)
      ) {
        // 권한 허용 로깅
        logPermission('접근 권한 허용', {
          userId,
          email: userEmail,
          resource: resourceKey,
          action,
          params,
        });
        return { can: true };
      }

      // 권한 없음 로깅
      logPermission(
        '접근 권한 없음',
        {
          userId,
          email: userEmail,
          resource: resourceKey,
          action,
          availableActions: resourcePermissions || [],
          params,
        },
        LogLevel.WARN,
      );
    } else {
      // 리소스에 대한 권한 정보 없음 로깅
      logPermission(
        '리소스에 대한 권한 정보 없음',
        {
          userId,
          email: userEmail,
          resource: resourceKey,
          action,
          params,
        },
        LogLevel.WARN,
      );
    }

    // 기본적으로 접근 거부 (필요에 따라 'list', 'show'는 허용 가능)
    return { can: false, reason: 'Forbidden' };
  },
  // options.buttons.hideIfUnauthorized = true일 경우, Refine은 버튼 렌더링 전에 can 호출하여 권한 확인
};
