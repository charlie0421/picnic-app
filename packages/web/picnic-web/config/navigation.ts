import { PortalType } from "@/utils/enums";
import menuConfig from './menu.json';

// 포탈 메뉴 구성
export const PORTAL_MENU = menuConfig.portals.map(portal => ({
    type: portal.type as PortalType,
    name: portal.name,
    path: portal.path,
}));

// 메인 네비게이션 메뉴 구성
export interface MenuItem {
    key: string;
    name: string;
    path: string;
    i18nKey?: string;
}

// 투표 서브메뉴 관계 설정
export const VOTE_SUB_PATHS = menuConfig.portals
    .find(portal => portal.type === 'vote')
    ?.subMenus?.map(menu => menu.path) || [];

export const MAIN_MENU: MenuItem[] = menuConfig.portals
    .find(portal => portal.type === 'vote')
    ?.subMenus || [];

// 포털 타입과 경로 간의 맵핑 (양방향 매핑)
export const PATH_TO_PORTAL_TYPE: Record<string, PortalType> = menuConfig.portals.reduce((acc, portal) => {
    acc[portal.path] = portal.type as PortalType;
    if (portal.subMenus) {
        portal.subMenus.forEach(menu => {
            acc[menu.path] = portal.type as PortalType;
        });
    }
    return acc;
}, {} as Record<string, PortalType>);

// 현재 경로가 어떤 포털 타입에 해당하는지 찾는 함수
export function getPortalTypeFromPath(path: string): PortalType {
    // 경로의 첫 번째 세그먼트 추출 (예: '/vote/chart' -> '/vote')
    const firstSegment = `/${path.split("/").filter(Boolean)[0]}`;
    return PATH_TO_PORTAL_TYPE[firstSegment] || PortalType.PUBLIC;
}

// 해당 경로가 VOTE 관련 경로인지 확인하는 함수
export function isVoteRelatedPath(path: string): boolean {
    return VOTE_SUB_PATHS.some((subPath) => path.startsWith(subPath));
}
