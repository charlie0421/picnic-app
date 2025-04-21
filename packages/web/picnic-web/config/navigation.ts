import { PortalType } from "@/utils/enums";

// 포털 메뉴 구성
export const PORTAL_MENU = [
    {
        type: PortalType.VOTE,
        name: "VOTE",
        path: "/vote",
    },
    {
        type: PortalType.COMMUNITY,
        name: "COMMUNITY",
        path: "/community",
    },
    {
        type: PortalType.PIC,
        name: "PIC",
        path: "/pic",
    },
    {
        type: PortalType.NOVEL,
        name: "NOVEL",
        path: "/novel",
    },
];
// 메인 네비게이션 메뉴 구성
export interface MenuItem {
    key: string;
    label: string;
    path: string;
    i18nKey?: string;
    children?: MenuItem[];
}

// 투표 서브메뉴 관계 설정
export const VOTE_SUB_PATHS = ["/vote", "/vote/chart", "/rewards"];

export const MAIN_MENU: MenuItem[] = [
    {
        key: "vote",
        label: "투표",
        path: "/vote",
        i18nKey: "nav_vote",
    },
    {
        key: "chart",
        label: "픽차트",
        path: "/vote/chart",
        i18nKey: "nav_picchart",
    },
    {
        key: "rewards",
        label: "리워드",
        path: "/rewards",
        i18nKey: undefined,
    },
    {
        key: "media",
        label: "미디어",
        path: "/media",
        i18nKey: "nav_media",
    },
    {
        key: "shop",
        label: "상점",
        path: "/shop",
        i18nKey: "nav_store",
    },
];

// 포털 타입과 경로 간의 맵핑 (양방향 매핑)
export const PATH_TO_PORTAL_TYPE: Record<string, PortalType> = {
    "/vote": PortalType.VOTE,
    "/rewards": PortalType.VOTE,
    "/community": PortalType.COMMUNITY,
    "/pic": PortalType.PIC,
    "/novel": PortalType.NOVEL,
    "/mypage": PortalType.MYPAGE,
    "/media": PortalType.PUBLIC,
};

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
