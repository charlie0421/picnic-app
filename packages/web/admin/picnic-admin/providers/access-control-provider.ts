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

// 리소스 이름을 DB 리소스 이름으로 자동 변환하는 함수
const convertToDatabaseResource = (resource: string): string => {
  // 특수 케이스만 매핑
  const specialCaseMapping: Record<string, string> = {
    artist_group: 'artists', // 예외 케이스
  };

  if (specialCaseMapping[resource]) {
    return specialCaseMapping[resource];
  }

  // 1. Group 접미사 제거
  if (resource.endsWith('Group')) {
    return resource.replace('Group', '');
  }

  // 2. 복합 리소스 이름에서 기본 부분 추출
  if (resource.includes('/') || resource.includes('_')) {
    const baseName = resource.split('/')[0].split('_')[0];
    // 단수형을 복수형으로 변환 (일반적인 규칙)
    return baseName.endsWith('y')
      ? baseName.slice(0, -1) + 'ies' // category -> categories
      : baseName.endsWith('s')
      ? baseName // statistics -> statistics (이미 복수형)
      : baseName + 's'; // vote -> votes
  }

  // 3. 기본 변환 (단수형을 복수형으로)
  if (!resource.endsWith('s') && !resource.includes('admin_')) {
    return resource.endsWith('y')
      ? resource.slice(0, -1) + 'ies' // category -> categories
      : resource + 's'; // vote -> votes
  }

  // 4. 기타 경우 그대로 반환 (admin_ 접두사 리소스 등)
  return resource;
};

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

    // 권한 스토어 접근
    const userPermissionsFromStore = getPermissionsFromStore();

    // 3. 메뉴 표시를 위한 권한 처리 (메뉴 표시 여부만 결정)
    // action이 'menu'인 경우 메뉴 표시 여부만 결정하므로 거의 모든 경우 허용
    if (action === 'menu') {
      // admin 메뉴는 별도 확인 (하위 권한 중 하나라도 있으면 표시)
      if (resource === 'admin') {
        if (userPermissionsFromStore === null)
          return Promise.resolve({ can: false });

        // 관리자 메뉴는 항상 표시 (권한은 하위 메뉴에서 체크)
        logPermission('can: 관리자 메뉴("admin") 표시 허용', {
          resource,
          action,
        });
        return Promise.resolve({ can: true });
      }

      // 다른 모든 메뉴는 표시 허용
      logPermission('can: 메뉴 표시 허용', { resource });
      return Promise.resolve({ can: true });
    }

    // 4. 특정 패턴의 리소스는 항상 페이지 접근 허용 (메뉴 표시뿐만 아니라 실제 페이지 접근도 허용)
    if (
      resource.includes('Group') ||
      resource.includes('/') ||
      resource.includes('_') ||
      resource === 'admin' || // admin 리소스도 허용
      (!resource.startsWith('admin_') && resource !== 'admin_no_access') // admin_ 접두사가 아닌 일반 리소스만 허용
    ) {
      // 리소스가 특정 포맷이거나 일반 리소스인 경우 허용
      logPermission('can: 리소스 페이지 접근 허용', {
        resource,
        action,
        reason:
          resource === 'admin'
            ? '관리자 페이지 접근 허용'
            : '일반/그룹 리소스 접근',
      });
      return Promise.resolve({ can: true });
    }

    // 5. 권한 확인 전 스토어 체크
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

    // 6. 슈퍼관리자 즉시 허용 로직 제거 (역할 기반으로 통합됨)

    // --- 모든 사용자의 권한 확인은 메모리 스토어를 통해 진행 ---

    try {
      // 리소스 이름 변환 (매핑 테이블 대신 함수 사용)
      const dbResourceName = convertToDatabaseResource(resource);
      // 매핑에 사용했던 모든 로직을 함수로 이동했으므로 simplifiedResourceName 불필요
      const dbActionName = actionMapping[action] || action;

      logPermission('can: 변환된 리소스/액션 확인', {
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

      logPermission('can: 특정 리소스 최종 접근 확인 (스토어 + 변환 적용)', {
        resource,
        action,
        dbResourceName,
        dbActionName,
        hasPermission,
      });

      // 7. admin 메뉴 및 하위 메뉴에 대한 추가 처리
      // admin 메뉴 자체 처리는 이미 위에서 처리됨

      // admin_ 접두사 하위 리소스(admin_roles 등)에 대한 페이지 접근 허용
      if (resource.startsWith('admin_')) {
        logPermission('can: 관리자 하위 리소스 페이지 접근 허용', {
          resource,
          action,
        });
        return Promise.resolve({ can: true });
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

      // 8. 최종 결과 반환
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
