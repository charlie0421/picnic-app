/**
 * 관리자 활동 로깅 서비스
 *
 * 관리자 페이지에서 발생하는 모든 중요 활동을 기록하기 위한 유틸리티
 */

import { supabaseBrowserClient } from '../supabase/client';
import { LogLevel, logSystem } from '../logger';

// 활동 타입 정의
export enum ActivityType {
  CREATE = 'CREATE', // 생성
  READ = 'READ', // 조회
  UPDATE = 'UPDATE', // 수정
  DELETE = 'DELETE', // 삭제
  LOGIN = 'LOGIN', // 로그인
  LOGOUT = 'LOGOUT', // 로그아웃
  EXPORT = 'EXPORT', // 내보내기
  IMPORT = 'IMPORT', // 가져오기
  APPROVE = 'APPROVE', // 승인
  REJECT = 'REJECT', // 거부
  OTHER = 'OTHER', // 기타
}

// 리소스 타입 정의
export enum ResourceType {
  USER = 'USER',
  VOTE = 'VOTE',
  BANNER = 'BANNER',
  MEDIA = 'MEDIA',
  SYSTEM = 'SYSTEM',
  SETTING = 'SETTING',
  REWARD = 'REWARD',
  CUSTOMER_GROUP = 'CUSTOMER_GROUP',
  NOTICE = 'NOTICE',
  FAQ = 'FAQ',
  QNA = 'QNA',
  COMMUNITY_GROUP = 'COMMUNITY_GROUP',
  BOARD = 'BOARD',
  POST = 'POST',
  ARTIST = 'ARTIST',
  ARTIST_GROUP = 'ARTIST_GROUP',
  STATISTICS_GROUP = 'STATISTICS_GROUP',
  STATISTICS_ADS = 'STATISTICS_ADS',
  RECEIPTS = 'RECEIPTS',
  CONFIG = 'CONFIG',
  APP_VERSION = 'APP_VERSION',
  ADMIN = 'ADMIN',
  ADMIN_ROLES = 'ADMIN_ROLES',
  ADMIN_PERMISSIONS = 'ADMIN_PERMISSIONS',
  ADMIN_ROLE_PERMISSIONS = 'ADMIN_ROLE_PERMISSIONS',
  ADMIN_USER_ROLES = 'ADMIN_USER_ROLES',
  ADMIN_NO_ACCESS = 'ADMIN_NO_ACCESS',
  ACTIVITIES = 'ACTIVITIES',
  DASHBOARD = 'DASHBOARD',
  POPUP = 'POPUP',
}

// 활동 로그 인터페이스
export interface ActivityLog {
  user_id?: string; // 활동을 수행한 관리자 ID
  activity_type: ActivityType; // 활동 유형
  resource_type: ResourceType; // 리소스 유형
  resource_id?: string; // 리소스 ID
  description: string; // 활동 설명
  details?: any; // 활동 세부 정보 (JSON)
  ip_address?: string; // IP 주소
  user_agent?: string; // 사용자 에이전트
}

/**
 * 관리자 활동 로그 기록
 *
 * @param activityLog 활동 로그 데이터
 * @returns Promise<boolean> 성공 여부
 */
export const logAdminActivity = async (
  activityLog: ActivityLog,
): Promise<boolean> => {
  try {
    // 시스템 로그에도 기록
    logSystem(`관리자 활동: ${activityLog.description}`, {
      activity_type: activityLog.activity_type,
      resource_type: activityLog.resource_type,
      resource_id: activityLog.resource_id,
    });

    // 필수 필드 검증
    if (
      !activityLog.activity_type ||
      !activityLog.resource_type ||
      !activityLog.description
    ) {
      console.error('활동 로그 필수 필드 누락:', {
        activity_type: activityLog.activity_type,
        resource_type: activityLog.resource_type,
        description: activityLog.description,
      });
      return false;
    }

    // 데이터베이스에 기록
    const { error } = await supabaseBrowserClient.from('activities').insert({
      user_id: activityLog.user_id,
      activity_type: activityLog.activity_type,
      resource_type: activityLog.resource_type,
      resource_id: activityLog.resource_id,
      description: activityLog.description,
      details: activityLog.details,
      ip_address: activityLog.ip_address,
      user_agent: activityLog.user_agent,
      timestamp: new Date().toISOString(),
    });

    if (error) {
      console.error('활동 로그 기록 실패:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('활동 로그 기록 중 오류 발생:', error);
    return false;
  }
};

/**
 * 현재 사용자 정보와 함께 활동 로그 기록
 *
 * @param activityType 활동 유형
 * @param resourceType 리소스 유형
 * @param description 활동 설명
 * @param resourceId 리소스 ID (선택사항)
 * @param details 세부 정보 (선택사항)
 */
export const logActivity = async (
  activityType: ActivityType,
  resourceType: ResourceType,
  description: string,
  resourceId?: string,
  details?: any,
): Promise<void> => {
  if (!activityType || !resourceType || !description) {
    console.error('로깅 필수 매개변수 누락', {
      activityType,
      resourceType,
      description,
    });
    return;
  }

  try {
    // 현재 로그인한 사용자 정보 가져오기
    const {
      data: { user },
      error: userError,
    } = await supabaseBrowserClient.auth.getUser();

    if (userError) {
      console.error('사용자 정보 가져오기 실패:', userError);
      // 사용자 정보 없이도 로깅 시도
    }

    // 사용자 에이전트 가져오기
    const userAgent = navigator.userAgent;

    // IP 주소는 클라이언트에서 직접 얻을 수 없음
    // 서버 측에서 처리하거나 별도 API를 통해 획득해야 함

    await logAdminActivity({
      user_id: user?.id,
      activity_type: activityType,
      resource_type: resourceType,
      resource_id: resourceId,
      description,
      details,
      user_agent: userAgent,
    });

    // 로그 성공 여부를 콘솔에 출력 (개발 환경에서만)
    if (process.env.NODE_ENV === 'development') {
      console.debug('활동 로그 기록:', {
        user_id: user?.id,
        activity_type: activityType,
        resource_type: resourceType,
        description,
      });
    }
  } catch (error) {
    console.error('활동 로깅 실패:', error);
  }
};

/**
 * 로그 조회 함수
 *
 * @param options 필터링 옵션
 * @returns Promise<ActivityLog[]> 활동 로그 배열
 */
export const getActivityLogs = async (options?: {
  limit?: number;
  offset?: number;
  user_id?: string;
  activity_type?: ActivityType;
  resource_type?: ResourceType;
  resource_id?: string;
  from_date?: Date;
  to_date?: Date;
}) => {
  try {
    let query = supabaseBrowserClient.from('activities').select('*');

    // 필터 적용
    if (options?.user_id) {
      query = query.eq('user_id', options.user_id);
    }

    if (options?.activity_type) {
      query = query.eq('activity_type', options.activity_type);
    }

    if (options?.resource_type) {
      query = query.eq('resource_type', options.resource_type);
    }

    if (options?.resource_id) {
      query = query.eq('resource_id', options.resource_id);
    }

    if (options?.from_date) {
      query = query.gte('timestamp', options.from_date.toISOString());
    }

    if (options?.to_date) {
      query = query.lte('timestamp', options.to_date.toISOString());
    }

    // 정렬 및 페이지네이션
    query = query.order('timestamp', { ascending: false });

    if (options?.limit) {
      query = query.limit(options.limit);
    } else {
      query = query.limit(100); // 기본 제한
    }

    if (options?.offset) {
      query = query.range(
        options.offset,
        options.offset + (options.limit || 100) - 1,
      );
    }

    const { data, error } = await query;

    if (error) {
      console.error('활동 로그 조회 실패:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('활동 로그 조회 중 오류 발생:', error);
    return [];
  }
};
