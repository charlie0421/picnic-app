/**
 * 활동 로깅을 위한 React 훅
 *
 * 관리자 페이지에서 활동 로깅을 손쉽게 할 수 있는 훅
 */

import { useCallback } from 'react';
import {
  logActivity,
  ActivityType,
  ResourceType,
} from '@/lib/services/activityLogger';

/**
 * 활동 로깅을 위한 훅
 *
 * @returns 다양한 활동 로깅 함수들을 포함한 객체
 */
export const useActivityLogger = () => {
  /**
   * 리소스 생성 활동 로깅
   *
   * @param resourceType 리소스 유형
   * @param description 활동 설명
   * @param resourceId 리소스 ID (선택사항)
   * @param details 세부 정보 (선택사항)
   */
  const logCreate = useCallback(
    (
      resourceType: ResourceType,
      description: string,
      resourceId?: string,
      details?: any,
    ) => {
      return logActivity(
        ActivityType.CREATE,
        resourceType,
        description,
        resourceId,
        details,
      );
    },
    [],
  );

  /**
   * 리소스 조회 활동 로깅
   *
   * @param resourceType 리소스 유형
   * @param description 활동 설명
   * @param resourceId 리소스 ID (선택사항)
   * @param details 세부 정보 (선택사항)
   */
  const logRead = useCallback(
    (
      resourceType: ResourceType,
      description: string,
      resourceId?: string,
      details?: any,
    ) => {
      return logActivity(
        ActivityType.READ,
        resourceType,
        description,
        resourceId,
        details,
      );
    },
    [],
  );

  /**
   * 리소스 수정 활동 로깅
   *
   * @param resourceType 리소스 유형
   * @param description 활동 설명
   * @param resourceId 리소스 ID (선택사항)
   * @param details 세부 정보 (선택사항)
   */
  const logUpdate = useCallback(
    (
      resourceType: ResourceType,
      description: string,
      resourceId?: string,
      details?: any,
    ) => {
      return logActivity(
        ActivityType.UPDATE,
        resourceType,
        description,
        resourceId,
        details,
      );
    },
    [],
  );

  /**
   * 리소스 삭제 활동 로깅
   *
   * @param resourceType 리소스 유형
   * @param description 활동 설명
   * @param resourceId 리소스 ID (선택사항)
   * @param details 세부 정보 (선택사항)
   */
  const logDelete = useCallback(
    (
      resourceType: ResourceType,
      description: string,
      resourceId?: string,
      details?: any,
    ) => {
      return logActivity(
        ActivityType.DELETE,
        resourceType,
        description,
        resourceId,
        details,
      );
    },
    [],
  );

  /**
   * 일반 활동 로깅
   *
   * @param activityType 활동 유형
   * @param resourceType 리소스 유형
   * @param description 활동 설명
   * @param resourceId 리소스 ID (선택사항)
   * @param details 세부 정보 (선택사항)
   */
  const log = useCallback(
    (
      activityType: ActivityType,
      resourceType: ResourceType,
      description: string,
      resourceId?: string,
      details?: any,
    ) => {
      return logActivity(
        activityType,
        resourceType,
        description,
        resourceId,
        details,
      );
    },
    [],
  );

  /**
   * 로그인 활동 로깅
   *
   * @param userId 사용자 ID
   * @param details 세부 정보 (선택사항)
   */
  const logLogin = useCallback((userId: string, details?: any) => {
    return logActivity(
      ActivityType.LOGIN,
      ResourceType.USER,
      '관리자 로그인',
      userId,
      details,
    );
  }, []);

  /**
   * 로그아웃 활동 로깅
   *
   * @param userId 사용자 ID
   * @param details 세부 정보 (선택사항)
   */
  const logLogout = useCallback((userId: string, details?: any) => {
    return logActivity(
      ActivityType.LOGOUT,
      ResourceType.USER,
      '관리자 로그아웃',
      userId,
      details,
    );
  }, []);

  return {
    logCreate,
    logRead,
    logUpdate,
    logDelete,
    logLogin,
    logLogout,
    log,
  };
};
