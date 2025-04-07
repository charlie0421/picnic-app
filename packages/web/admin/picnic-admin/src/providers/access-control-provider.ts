'use client';

import { AccessControlProvider } from '@refinedev/core';
import { authProviderClient } from './auth-provider/auth-provider.client';

export const accessControlProvider: AccessControlProvider = {
  can: async ({ resource, action, params }) => {
    // 로그인하지 않은 사용자는 접근 불가
    const { authenticated } = await authProviderClient.check?.() || {};
    if (!authenticated) {
      return { can: false, reason: 'Unauthorized' };
    }

    // 사용자의 권한 가져오기
    const permissions = await authProviderClient.getPermissions?.();

    // permissions가 Record<string, string[]> 형태라고 가정
    if (permissions && typeof permissions === 'object' && resource) {
      const resourcePermissions = (permissions as Record<string, string[]>)[resource];
      if (Array.isArray(resourcePermissions) && resourcePermissions.includes(action)) {
        return { can: true };
      }
    }

    // 기본적으로 접근 거부 (필요에 따라 'list', 'show'는 허용 가능)
    return { can: false, reason: 'Forbidden' };
  },
  // options.buttons.hideIfUnauthorized = true일 경우, Refine은 버튼 렌더링 전에 can 호출하여 권한 확인
}; 