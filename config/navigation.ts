import { PortalType } from "@/utils/enums";
import menuConfig from './menu.json';
import { SUPPORTED_LANGUAGES } from "./settings";

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
    // 기본 경로 매핑
    acc[portal.path] = portal.type as PortalType;
    
    // 언어별 경로 매핑
    SUPPORTED_LANGUAGES.forEach(lang => {
        acc[`/${lang}${portal.path}`] = portal.type as PortalType;
    });

    // 서브메뉴 경로 매핑
    if (portal.subMenus) {
        portal.subMenus.forEach(menu => {
            acc[menu.path] = portal.type as PortalType;
            // 서브메뉴의 언어별 경로 매핑
            SUPPORTED_LANGUAGES.forEach(lang => {
                acc[`/${lang}${menu.path}`] = portal.type as PortalType;
            });
        });
    }
    return acc;
}, {} as Record<string, PortalType>);

// 현재 경로가 어떤 포털 타입에 해당하는지 찾는 함수
export function getPortalTypeFromPath(path: string): PortalType {
    // 언어 코드를 제거한 경로 추출
    const pathWithoutLang = path.replace(/^\/(ko|en|ja|zh)/, '');
    // 경로의 첫 번째 세그먼트 추출 (예: '/vote/chart' -> '/vote')
    const firstSegment = `/${pathWithoutLang.split("/").filter(Boolean)[0]}`;
    return PATH_TO_PORTAL_TYPE[firstSegment] || PortalType.PUBLIC;
}

// 투표 관련 경로인지 확인하는 함수
export function isVoteRelatedPath(path: string): boolean {
    const pathWithoutLang = path.replace(/^\/(ko|en|ja|zh)/, '');
    return VOTE_SUB_PATHS.some(subPath => pathWithoutLang.startsWith(subPath));
}
