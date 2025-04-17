'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import {
  ActivityType,
  ResourceType,
  logActivity,
} from '@/lib/services/activityLogger';
import { useRouterContext, useResource } from '@refinedev/core';

/**
 * 페이지 접근 활동을 자동으로 로깅하는 컴포넌트
 * 레이아웃 내부에서 사용됩니다.
 */
export default function ActivityLogger() {
  const pathname = usePathname();
  const [loggedPaths, setLoggedPaths] = useState<string[]>([]);
  const { resources } = useResource();

  // 페이지 접근 로깅
  useEffect(() => {
    const logPageAccess = async () => {
      // 이미 로깅된 경로는 중복 로깅하지 않음
      if (loggedPaths.includes(pathname)) {
        return;
      }

      try {
        // 현재 경로와 일치하는 리소스 찾기
        const currentResource = resources.find((resource) => {
          // 리소스 경로가 현재 경로와 일치하는지 확인
          const resourcePaths = [
            resource.list,
            resource.create,
            resource.edit,
            resource.show,
          ].filter(Boolean);

          // 경로 매칭 (파라미터 처리: '/vote/edit/:id' -> '/vote/edit/' 형태로 비교)
          return resourcePaths.some((path) => {
            if (!path) return false;
            const normalizedPath =
              typeof path === 'string' ? path.split(':')[0] : path; // ':id' 같은 파라미터 제거
            return pathname.startsWith(
              typeof normalizedPath === 'string' ? normalizedPath : '',
            );
          });
        });

        if (currentResource) {
          // 메타데이터에서 리소스 타입 직접 가져오기
          const resourceMeta = currentResource.meta as any;
          const resourceType =
            resourceMeta?.resourceType || ResourceType.SYSTEM;

          // 리소스 유형 문자열 (SYSTEM -> "시스템" 등으로 변환)
          const resourceTypeStr = getResourceTypeLabel(resourceType);

          // 메뉴 라벨 기반으로 설명 생성 (리소스 유형 포함)
          let description = `[${resourceTypeStr}] ${
            resourceMeta?.label || currentResource.name
          } 페이지 접근`;

          // 액션(list, create, edit, show) 기반 설명 상세화
          if (currentResource.list && pathname === currentResource.list) {
            description = `[${resourceTypeStr}] ${
              resourceMeta?.list?.label || '목록'
            } 페이지 접근`;
          } else if (
            currentResource.create &&
            typeof currentResource.create === 'string' &&
            pathname.startsWith(currentResource.create.split(':')[0])
          ) {
            description = `[${resourceTypeStr}] ${
              resourceMeta?.create?.label || '생성'
            } 페이지 접근`;
          } else if (currentResource.edit && pathname.includes('/edit/')) {
            description = `[${resourceTypeStr}] ${
              resourceMeta?.edit?.label || '수정'
            } 페이지 접근`;
          } else if (currentResource.show && pathname.includes('/show/')) {
            description = `[${resourceTypeStr}] ${
              resourceMeta?.show?.label || '상세'
            } 페이지 접근`;
          }

          // 콘솔에 로깅 시도 기록 (개발 환경에서만)
          if (process.env.NODE_ENV === 'development') {
            console.debug('활동 로깅 시도:', {
              path: pathname,
              resourceType,
              description,
              resource: currentResource.name,
            });
          }

          // 활동 로깅
          await logActivity(
            ActivityType.READ,
            resourceType,
            description,
            undefined,
            { path: pathname },
          );

          // 로깅된 경로 저장
          setLoggedPaths((prev) => [...prev, pathname]);
        }
      } catch (error) {
        console.error('페이지 접근 로깅 실패:', error);
      }
    };

    logPageAccess();
  }, [pathname, loggedPaths, resources]);

  // 이 컴포넌트는 UI를 렌더링하지 않음
  return null;
}

/**
 * ResourceType을 한글 설명으로 변환
 */
function getResourceTypeLabel(resourceType: ResourceType): string {
  const resourceTypeLabels: Record<string, string> = {
    [ResourceType.USER]: '사용자',
    [ResourceType.VOTE]: '투표',
    [ResourceType.BANNER]: '배너',
    [ResourceType.MEDIA]: '미디어',
    [ResourceType.SYSTEM]: '시스템',
    [ResourceType.SETTING]: '설정',
    [ResourceType.REWARD]: '리워드',
    [ResourceType.CUSTOMER_GROUP]: '고객 관리',
    [ResourceType.NOTICE]: '공지사항',
    [ResourceType.FAQ]: 'FAQ',
    [ResourceType.QNA]: 'Q&A',
    [ResourceType.COMMUNITY_GROUP]: '커뮤니티',
    [ResourceType.BOARD]: '게시판',
    [ResourceType.POST]: '게시글',
    [ResourceType.ARTIST]: '아티스트',
    [ResourceType.ARTIST_GROUP]: '아티스트 그룹',
    [ResourceType.STATISTICS_GROUP]: '통계',
    [ResourceType.STATISTICS_ADS]: '광고 통계',
    [ResourceType.RECEIPTS]: '영수증 통계',
    [ResourceType.CONFIG]: '앱 설정',
    [ResourceType.ADMIN]: '관리자',
    [ResourceType.ADMIN_ROLES]: '역할 관리',
    [ResourceType.ADMIN_PERMISSIONS]: '권한 관리',
    [ResourceType.ADMIN_ROLE_PERMISSIONS]: '역할-권한',
    [ResourceType.ADMIN_USER_ROLES]: '사용자-역할',
    [ResourceType.ADMIN_NO_ACCESS]: '접근 불가',
    [ResourceType.ACTIVITIES]: '활동 로그',
    [ResourceType.DASHBOARD]: '대시보드',
  };

  return resourceTypeLabels[resourceType] || resourceType.toString();
}
