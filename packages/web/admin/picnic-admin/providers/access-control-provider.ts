'use client';

import { AccessControlProvider } from '@refinedev/core';
// import { PERMISSION } from '@/interfaces'; // PERMISSION 타입 사용 안 함
import { logPermission, LogLevel } from '@/lib/logger';
// import { supabaseBrowserClient } from '@utils/supabase/client'; // 직접 사용 안 함
// import { authProviderClient } from './auth-provider/auth-provider.client'; // getIdentity 호출 안 하므로 제거 가능
import { getPermissions as getPermissionsFromStore } from '@/stores/permissionStore'; // 스토어에서 권한 가져오기

// UserIdentity 인터페이스 불필요
// interface UserIdentity {
//   id?: string;
//   email?: string;
//   name?: string;
//   [key: string]: any;
// }

// Refine 리소스 이름을 DB 리소스 이름으로 매핑
const resourceNameMapping: Record<string, string> = {
  admin_roles: 'admin_roles',
  admin_permissions: 'admin_permissions',
  admin_user_roles: 'admin_user_roles', // 'users' 리소스에 대한 권한으로 매핑 (확인 필요)
  admin_role_permissions: 'admin_role_permissions', // 역할 또는 권한 리소스에 대한 권한으로 매핑 (확인 필요, 임시로 roles)
  artist: 'artists',
  artist_group: 'artists', // 그룹도 artists 리소스 권한 사용 가정 (확인 필요)
  vote: 'votes',
  media: 'media',
  // DB에 있는 다른 리소스 이름도 필요시 추가
};

// Refine 액션을 DB 액션으로 매핑 (list->read, edit->update, show->read)
const actionMapping: Record<string, string> = {
  list: 'read',
  edit: 'update',
  show: 'read',
  // create, delete는 이름이 동일하므로 명시적 매핑 불필요
};

// 내부 캐시 변수 제거
// let userPermissionsCache: Record<string, string[]> | null = null;
// let cacheUserId: string | null = null;

export const accessControlProvider: AccessControlProvider = {
  can: async ({ resource, action, params }) => {
    // 1. 리소스 유효성 검사
    if (!resource) {
      logPermission(
        'can: 리소스 정보 없음',
        { action, params },
        LogLevel.ERROR,
      );
      return Promise.resolve({ can: false, reason: 'Invalid resource' });
    }

    logPermission('can: 권한 확인 시작 (메모리 스토어 확인 + 매핑)', {
      resource,
      action,
      params,
    });

    // 2. 로그인 리소스는 항상 허용
    if (resource === 'login') {
      logPermission('can: 로그인 리소스 접근 허용', { resource });
      return Promise.resolve({ can: true });
    }

    // 3. getIdentity 호출 제거 및 permissionStore 직접 확인
    const userPermissionsFromStore = getPermissionsFromStore();

    if (userPermissionsFromStore === null) {
      // 스토어가 null이면 비로그인 또는 로딩 전 상태로 간주
      logPermission(
        'can: 메모리 스토어에 권한 없음 (비로그인 또는 로딩 전)',
        { resource, action },
        LogLevel.INFO, // 비로그인 상태는 일반적이므로 INFO 레벨로 변경
      );
      // 로그인 페이지가 아니고 스토어가 null이면 접근 불가
      return Promise.resolve({
        can: false,
        reason: 'Permissions not available',
      });
    }

    // 스토어에 권한 객체가 있으면 (빈 객체 포함) 계속 진행
    // 로그 메시지 수정: userId 정보 제거
    logPermission('can: 메모리 스토어에서 권한 로드 확인됨', {
      storeKeys: Object.keys(userPermissionsFromStore),
    });

    // 4. 슈퍼관리자 즉시 허용 로직 제거 (역할 기반으로 통합됨)

    // --- 모든 사용자의 권한 확인은 메모리 스토어를 통해 진행 ---

    try {
      // 5. 스토어 권한과 매핑을 이용한 확인
      const dbResourceName = resourceNameMapping[resource] || resource;
      const dbActionName = actionMapping[action] || action;

      logPermission('can: 매핑된 리소스/액션 확인', {
        requestedResource: resource,
        requestedAction: action,
        dbResourceName,
        dbActionName,
      });

      let hasPermission = false;
      if (userPermissionsFromStore[dbResourceName]) {
        const allowedActions = userPermissionsFromStore[dbResourceName];
        if (
          allowedActions.includes(dbActionName) ||
          allowedActions.includes('*')
        ) {
          hasPermission = true;
        }
      }

      logPermission('can: 특정 리소스 최종 접근 확인 (스토어 + 매핑 적용)', {
        resource,
        action,
        dbResourceName,
        dbActionName,
        hasPermission,
      });

      // 6. admin 메뉴 자체 및 no-access 페이지 처리 (스토어 기반)
      if (resource === 'admin') {
        const adminResources = [
          'roles',
          'permissions',
          'users',
          'admin_roles',
          'admin_permissions',
          'admin_user_roles',
          'admin_role_permissions',
        ];
        const hasAdminMenuAccess = adminResources.some(
          (res) => userPermissionsFromStore[res]?.length > 0,
        );
        logPermission('can: 관리자 메뉴("admin") 접근 확인 (스토어+매핑)', {
          hasAdminMenuAccess,
        });
        return Promise.resolve({ can: hasAdminMenuAccess });
      }

      // 권한 없는 사용자 처리 (스토어 기준)
      if (resource === 'admin_no_access') {
        const canAccessAnyMenu =
          Object.keys(userPermissionsFromStore).length > 0;

        if (!canAccessAnyMenu) {
          logPermission(
            'can: 권한 없는 사용자 -> no-access 페이지 허용 (스토어)',
            {},
          );
          return Promise.resolve({ can: true });
        }
        hasPermission = false;
      }

      // 7. 최종 결과 반환
      return Promise.resolve({
        can: hasPermission,
        reason: hasPermission ? undefined : 'Access Denied by Store/Mapping',
      });
    } catch (error) {
      logPermission(
        'can: 접근 제어 로직 전체 오류 발생',
        { resource, action, error },
        LogLevel.ERROR,
      );
      console.error('Access control error:', error);
      return Promise.resolve({ can: false, reason: 'Access control error' });
    }
  },
};
