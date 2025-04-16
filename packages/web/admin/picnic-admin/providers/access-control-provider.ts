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
    artist: 'artists',
    vote: 'votes',
    banner: 'banner',
    media: 'media',
    user_profiles: 'user_profiles',
    reward: 'reward', 
    posts: 'posts',
    boards: 'boards',
    notices: 'notices',
    faqs: 'faqs',
    qnas: 'qnas',
    config: 'config',
    // 통계 관련
    statistics_ads: 'statistics',
    receipts: 'statistics',
    // 아티스트 관련
    artistGroup: 'artists',
    // 통계 관련
    statisticsGroup: 'statistics',
    // 커뮤니티 관련
    communityGroup: 'posts', 
    // CS 관련
    customerGroup: 'notices',
    // 대시 표기법 변환
    'artist-group': 'artists',
  };

  console.log('리소스 변환 시도:', resource);

  // 특수 매핑이 있으면 그것을 사용
  if (specialCaseMapping[resource]) {
    const mappedResource = specialCaseMapping[resource];
    console.log(`리소스 특수 매핑: ${resource} -> ${mappedResource}`);
    return mappedResource;
  }

  // 대시 기호를 언더스코어로 변환
  if (resource.includes('-')) {
    resource = resource.replace(/-/g, '_');
  }

  // 1. Group 접미사 제거
  if (resource.endsWith('Group')) {
    const result = resource.replace('Group', '');
    console.log(`그룹 접미사 제거: ${resource} -> ${result}`);
    return result;
  }

  // 2. 복합 리소스 이름에서 기본 부분 추출
  if (resource.includes('/') || resource.includes('_')) {
    const baseName = resource.split('/')[0].split('_')[0];
    // 단수형을 복수형으로 변환 (일반적인 규칙)
    const result = baseName.endsWith('y')
      ? baseName.slice(0, -1) + 'ies' // category -> categories
      : baseName.endsWith('s')
      ? baseName // statistics -> statistics (이미 복수형)
      : baseName + 's'; // vote -> votes
    
    console.log(`복합 리소스 변환: ${resource} -> ${result}`);
    return result;
  }

  // 3. 기본 변환 (단수형을 복수형으로)
  if (!resource.endsWith('s') && !resource.includes('admin_')) {
    const result = resource.endsWith('y')
      ? resource.slice(0, -1) + 'ies' // category -> categories
      : resource + 's'; // vote -> votes
    
    console.log(`단수형->복수형 변환: ${resource} -> ${result}`);
    return result;
  }

  // 4. 기타 경우 그대로 반환 (admin_ 접두사 리소스 등)
  console.log(`리소스 그대로 사용: ${resource}`);
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

    // 로그인 관련 및 공개 리소스 목록
    const publicResources = ['login', 'logout', 'reset-password', 'forgot-password', 'register'];
    if (publicResources.includes(resource)) {
      logPermission('can: 공개 리소스 접근 허용', { resource });
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

      // 인증되지 않은 상태에서는 메뉴 접근 차단
      if (userPermissionsFromStore === null) {
        logPermission('can: 비인증 상태 메뉴 접근 차단', { resource });
        return Promise.resolve({ can: false });
      }

      // 인증된 사용자에게 권한 체크 후 메뉴 표시 허용
      // 리소스 이름 변환
      const dbResourceName = convertToDatabaseResource(resource);
      
      // 권한이 있는지 확인
      const hasMenuPermission = (
        userPermissionsFromStore[dbResourceName] && 
        (userPermissionsFromStore[dbResourceName].includes('read') || 
         userPermissionsFromStore[dbResourceName].includes('*'))
      );
      
      // 디버깅용 상세 로그 추가
      console.log('메뉴 권한 체크 (상세):', {
        resource,
        action,
        dbResourceName,
        dbPermissions: userPermissionsFromStore[dbResourceName],
        allPermissions: userPermissionsFromStore,
        hasMenuPermission,
      });
      
      // 그룹 메뉴는 하위 메뉴 중 하나라도 접근 가능하면 표시
      const isGroupMenu = resource.endsWith('Group');
      if (isGroupMenu) {
        // 모든 권한에서 이 그룹에 속하는 리소스가 있는지 확인
        const baseGroupName = resource.replace('Group', '');
        
        // 특수 그룹 매핑 (API 권한과 메뉴 그룹 간의 매핑)
        const groupMappings: Record<string, string[]> = {
          'artistGroup': ['artists'],
          'statisticsGroup': ['statistics'],
          'communityGroup': ['posts', 'boards'],
          'customerGroup': ['notices', 'faqs', 'qnas'],
        };
        
        // 그룹에 대한 특별 매핑이 있으면 사용
        const targetResources = groupMappings[resource] || [baseGroupName];
        
        // 권한 목록에서 이 그룹에 속하는 리소스 찾기
        const groupResources = Object.keys(userPermissionsFromStore).filter(
          resName => targetResources.some(target => 
            resName === target || resName.startsWith(target)
          )
        );
        
        console.log('그룹 메뉴 권한 체크:', {
          resource,
          baseGroupName,
          targetResources,
          groupResources,
          userPermissions: userPermissionsFromStore
        });
        
        const hasAnySubResourcePermission = groupResources.length > 0;
        if (hasAnySubResourcePermission) {
          logPermission('can: 그룹 메뉴 표시 허용 (하위 리소스 접근 가능)', { 
            resource, 
            groupResources 
          });
          return Promise.resolve({ can: true });
        }
        
        // 그룹 메뉴이면서 권한이 없으면 차단
        logPermission('can: 그룹 메뉴 접근 거부 (하위 리소스 권한 없음)', { resource });
        return Promise.resolve({ can: false });
      }
      
      // dashboard는 모든 사용자에게 표시 (예외)
      if (resource === 'dashboard') {
        logPermission('can: 대시보드 메뉴 표시 허용', { resource });
        return Promise.resolve({ can: true });
      }
      
      // 권한 있는 메뉴만 표시 허용
      logPermission(`can: 메뉴 ${hasMenuPermission ? '표시 허용' : '접근 거부'}`, { 
        resource,
        dbResourceName,
        hasPermission: hasMenuPermission
      });
      
      return Promise.resolve({ can: hasMenuPermission });
    }

    // 4. 특정 패턴의 리소스는 항상 페이지 접근 허용 (메뉴 표시뿐만 아니라 실제 페이지 접근도 허용)
    if (
      resource.includes('Group') ||
      resource.includes('/') ||
      resource.includes('_') ||
      resource === 'admin' || // admin 리소스도 허용
      (!resource.startsWith('admin_') && resource !== 'admin_no_access') // admin_ 접두사가 아닌 일반 리소스만 허용
    ) {
      // 인증되지 않은 상태에서는 페이지 접근 차단
      if (userPermissionsFromStore === null) {
        logPermission('can: 비인증 상태 페이지 접근 차단', { resource });
        return Promise.resolve({ can: false });
      }

      // 리소스 이름 변환을 통해 권한 체크
      const dbResourceName = convertToDatabaseResource(resource);
      // 읽기 권한이 있는지 확인
      const hasReadPermission = (
        userPermissionsFromStore[dbResourceName] && 
        (userPermissionsFromStore[dbResourceName].includes('read') || 
         userPermissionsFromStore[dbResourceName].includes('*'))
      );

      // 그룹 메뉴인 경우 하위 권한 확인
      const isGroupResource = resource.includes('Group');
      if (isGroupResource) {
        // 그룹 메뉴의 하위 리소스 접근 권한 확인
        const baseGroupName = resource.replace('Group', '');
        const groupResources = Object.keys(userPermissionsFromStore).filter(
          resName => resName.startsWith(baseGroupName) || resName.includes(baseGroupName)
        );
        
        const hasAnySubResourcePermission = groupResources.length > 0;
        if (hasAnySubResourcePermission) {
          logPermission('can: 그룹 리소스 접근 허용 (하위 리소스 권한 있음)', { 
            resource, 
            groupResources 
          });
          return Promise.resolve({ can: true });
        }
        
        // 그룹 리소스이면서 하위 리소스에 권한 없으면 접근 차단
        logPermission('can: 그룹 리소스 접근 거부 (하위 리소스 권한 없음)', { resource });
        return Promise.resolve({ can: false });
      }

      // admin 리소스는 별도 체크
      if (resource === 'admin') {
        // 권한 관리 메뉴에 대한 접근
        const adminResources = Object.keys(userPermissionsFromStore).filter(
          name => name.startsWith('admin_')
        );
        
        const hasAdminPermission = adminResources.length > 0;
        
        logPermission(`can: 관리자 페이지 접근 ${hasAdminPermission ? '허용' : '거부'}`, {
          resource,
          hasAdminPermission,
          adminResources
        });
        
        return Promise.resolve({ can: hasAdminPermission });
      }

      // admin_ 접두사 리소스는 항상 DB에서 체크
      if (resource.startsWith('admin_')) {
        logPermission(`can: 관리자 하위 리소스 페이지 접근 ${hasReadPermission ? '허용' : '거부'}`, {
          resource,
          dbResourceName,
          action,
          hasReadPermission
        });
        return Promise.resolve({ can: hasReadPermission });
      }

      // 일반 리소스는 권한 체크
      logPermission(`can: 리소스 페이지 접근 ${hasReadPermission ? '허용' : '거부'}`, {
        resource,
        action,
        dbResourceName,
        hasReadPermission
      });
      
      return Promise.resolve({ can: hasReadPermission });
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

      // admin_ 접두사 하위 리소스(admin_roles 등)는 실제 권한 체크
      if (resource.startsWith('admin_')) {
        // admin_ 리소스에 대한 권한 확인
        const hasAdminPermission = (
          userPermissionsFromStore[dbResourceName] && 
          (userPermissionsFromStore[dbResourceName].includes(dbActionName) || 
           userPermissionsFromStore[dbResourceName].includes('*'))
        );
        
        logPermission(`can: 관리자 하위 리소스 페이지 접근 ${hasAdminPermission ? '허용' : '거부'}`, {
          resource,
          action,
          dbResourceName,
          dbActionName,
          hasAdminPermission
        });
        
        return Promise.resolve({ can: hasAdminPermission });
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
