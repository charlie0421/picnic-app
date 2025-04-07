'use client';

import { useEffect } from 'react';
import { useIsAuthenticated, useGetIdentity } from '@refinedev/core';
import { authProviderClient } from '@/providers/auth-provider/auth-provider.client';
import { setPermissions, getPermissions } from '@/stores/permissionStore';
import { logPermission, LogLevel } from '@/lib/logger';
import { usePermissionLoading } from '@/contexts/PermissionLoadingContext';

// 사용자 식별 정보 타입 정의 (isSuperAdmin 제거)
interface UserIdentity {
  id: string; // id는 필수
  email?: string;
  name?: string;
  // isSuperAdmin?: boolean;
  [key: string]: any;
}

/**
 * 사용자 인증 상태에 따라 권한을 로드하고 상태 저장소에 저장하는 컴포넌트.
 * 애플리케이션 레이아웃의 상위 레벨에서 한 번만 렌더링되어야 합니다.
 */
export const PermissionLoader: React.FC<React.PropsWithChildren> = ({
  children,
}) => {
  const { data: isAuthenticated, isLoading: isAuthLoading } =
    useIsAuthenticated();
  const { data: identity, isLoading: isIdentityLoading } =
    useGetIdentity<UserIdentity>();
  const { setIsLoadingPermissions } = usePermissionLoading();

  useEffect(() => {
    const loadPermissions = async () => {
      // 로딩 시작 상태 설정
      setIsLoadingPermissions(true);
      try {
        if (isAuthenticated && identity?.id) {
          logPermission('PermissionLoader: 인증됨, 권한 로드 시도', {
            userId: identity.id,
          });
          // 이미 로드된 권한이 있는지 확인 (중복 로드 방지)
          if (getPermissions() === null) {
            try {
              // authProvider의 getPermissions를 호출하여 권한 맵 가져오기
              const fetchedPermissions =
                await authProviderClient.getPermissions?.();
              if (fetchedPermissions) {
                setPermissions(fetchedPermissions as Record<string, string[]>);
                logPermission('PermissionLoader: 권한 로드 및 저장 성공', {
                  userId: identity.id,
                  permissionKeys: Object.keys(fetchedPermissions),
                });
              } else {
                setPermissions({}); // 권한이 없는 경우 빈 객체 저장
                logPermission(
                  'PermissionLoader: 사용자에게 권한 없음',
                  { userId: identity.id },
                  LogLevel.WARN,
                );
              }
            } catch (error) {
              setPermissions({}); // 오류 발생 시 안전하게 빈 객체 저장
              logPermission(
                'PermissionLoader: 권한 로드 중 오류 발생',
                { userId: identity.id, error },
                LogLevel.ERROR,
              );
              console.error('Failed to load permissions:', error);
            }
          } else {
            logPermission('PermissionLoader: 이미 권한 로드됨, 건너뜀', {
              userId: identity.id,
            });
          }
        } else if (!isAuthenticated) {
          // 로그아웃 상태 또는 인증 확인 전
          if (getPermissions() !== null) {
            logPermission('PermissionLoader: 로그아웃됨, 권한 초기화');
            setPermissions(null); // 로그아웃 시 권한 정보 초기화
          }
        }
      } catch (error) {
        setPermissions({}); // 오류 발생 시 안전하게 빈 객체 저장
        logPermission(
          'PermissionLoader: 권한 로드 중 오류 발생',
          { userId: identity?.id, error },
          LogLevel.ERROR,
        );
        console.error('Failed to load permissions:', error);
      } finally {
        // 로딩 완료 상태 설정 (성공/실패/이미 로드됨/로그아웃 모든 경우)
        setIsLoadingPermissions(false);
      }
    };

    // 인증 상태 및 사용자 정보 로딩이 완료된 후 권한 로드 실행
    if (!isAuthLoading && !isIdentityLoading) {
      loadPermissions();
    } else if (!isAuthLoading && !isAuthenticated) {
      // 인증 로딩은 끝났지만 비인증 상태가 확실한 경우 (로그아웃 직후 등)
      // 즉시 로딩 완료 처리 가능
      setIsLoadingPermissions(false);
      setPermissions(null); // 확실히 로그아웃 상태이므로 권한 null 처리
    }
  }, [
    isAuthenticated,
    identity,
    isAuthLoading,
    isIdentityLoading,
    setIsLoadingPermissions,
  ]);

  // 이 컴포넌트는 UI를 렌더링하지 않고 자식 요소만 반환합니다.
  return <>{children}</>;
};
