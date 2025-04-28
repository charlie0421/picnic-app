import { MetadataRoute } from "next";
import { createClient } from "../utils/supabase-server-client";
import { Database } from "../types/supabase";
import { SITE_URL, STATIC_PAGES } from "./constants/static-pages";
import fs from "fs";
import path from "path";

interface Vote {
    id: number;
    title: any;
    created_at: string;
    updated_at: string;
    status?: string; // 투표 상태 (활성/예정/종료)
}

// 파일 시스템에서 app 디렉토리의 페이지를 자동으로 탐지하는 함수
function detectAppPages(): string[] {
    const appDir = path.join(process.cwd(), "app");
    const detectedPaths: string[] = [];

    // 재귀적으로 디렉토리 탐색
    function scanDir(dir: string, basePath: string = "") {
        const entries = fs.readdirSync(dir, { withFileTypes: true });

        for (const entry of entries) {
            // 특수 디렉토리 스킵
            if (
                entry.name.startsWith("_") || entry.name.startsWith(".") ||
                entry.name === "api" || entry.name === "components" ||
                entry.name === "hooks" || entry.name === "utils" ||
                entry.name === "constants" || entry.name === "types" ||
                entry.name === "styles"
            ) {
                continue;
            }

            const entryPath = path.join(dir, entry.name);

            if (entry.isDirectory()) {
                // 라우트 그룹 처리 ((main), (auth) 등)
                if (entry.name.startsWith("(") && entry.name.endsWith(")")) {
                    scanDir(entryPath, basePath);
                } else {
                    const newBasePath = basePath
                        ? `${basePath}/${entry.name}`
                        : entry.name;
                    scanDir(entryPath, newBasePath);
                }
            } else if (
                entry.isFile() &&
                (entry.name === "page.tsx" || entry.name === "page.jsx")
            ) {
                // page.tsx 또는 page.jsx 파일이 있으면 해당 경로는 페이지
                if (basePath && !detectedPaths.includes(basePath)) {
                    detectedPaths.push(basePath);
                }
            }
        }
    }

    try {
        scanDir(appDir);
        return detectedPaths;
    } catch (error) {
        console.error("페이지 탐지 중 오류:", error);
        return [];
    }
}

// Supabase 클라이언트를 사용하여 투표 데이터를 가져오는 함수
async function fetchVoteData(): Promise<Vote[]> {
    try {
        const supabase = await createClient();
        const now = new Date().toISOString();

        // 활성화된 투표 가져오기
        const { data: activeVotes, error: activeError } = await supabase
            .from("vote")
            .select("id, title, created_at, updated_at")
            .is("deleted_at", null)
            .lte("start_at", now)
            .gt("stop_at", now)
            .order("created_at", { ascending: false });

        if (activeError) throw activeError;

        // 예정된 투표 가져오기 (시작일이 미래인 투표)
        const { data: upcomingVotes, error: upcomingError } = await supabase
            .from("vote")
            .select("id, title, created_at, updated_at")
            .is("deleted_at", null)
            .gt("start_at", now)
            .order("start_at", { ascending: true });

        if (upcomingError) throw upcomingError;

        // 종료된 투표 가져오기 (최근 30개)
        const { data: pastVotes, error: pastError } = await supabase
            .from("vote")
            .select("id, title, created_at, updated_at")
            .is("deleted_at", null)
            .lte("stop_at", now)
            .order("stop_at", { ascending: false })
            .limit(30);

        if (pastError) throw pastError;

        // 상태 플래그 추가하기
        const formattedActiveVotes = (activeVotes || []).map((vote) => ({
            ...vote,
            status: "active",
        }));

        const formattedUpcomingVotes = (upcomingVotes || []).map((vote) => ({
            ...vote,
            status: "upcoming",
        }));

        const formattedPastVotes = (pastVotes || []).map((vote) => ({
            ...vote,
            status: "past",
        }));

        // 모든 투표 데이터 병합
        return [
            ...formattedActiveVotes,
            ...formattedUpcomingVotes,
            ...formattedPastVotes,
        ];
    } catch (error) {
        console.error("사이트맵 생성 중 오류:", error);
        return []; // 오류 발생 시 빈 배열 반환
    }
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
    // 정적 페이지 URL 생성 (수동으로 정의한 목록)
    const staticUrls: MetadataRoute.Sitemap = STATIC_PAGES.map((page) => ({
        url: `${SITE_URL}${page.path ? `/${page.path}` : ""}`,
        lastModified: new Date(),
        changeFrequency: page.changeFreq as
            | "hourly"
            | "daily"
            | "weekly"
            | "monthly",
        priority: page.priority,
    }));

    // 자동 감지된, 등록되지 않은 페이지 URL 생성
    const detectedPages = detectAppPages();
    const manuallyDefinedPaths = STATIC_PAGES.map((page) => page.path);

    const autoDetectedUrls: MetadataRoute.Sitemap = detectedPages
        .filter((page) => !manuallyDefinedPaths.includes(page)) // 수동 등록된 페이지 제외
        .map((page) => ({
            url: `${SITE_URL}/${page}`,
            lastModified: new Date(),
            changeFrequency: "monthly" as const,
            priority: 0.5,
        }));

    // 모든 정적 URL 합치기
    const allStaticUrls = [...staticUrls, ...autoDetectedUrls];

    try {
        // 투표 데이터 가져오기
        const votes = await fetchVoteData();

        // 각 투표에 대한 URL 생성 (상태에 따라 우선순위 차별화)
        const voteUrls: MetadataRoute.Sitemap = votes.map((vote) => {
            // 상태에 따라 우선순위 결정
            let priority = 0.8;
            let changeFrequency: "hourly" | "daily" | "weekly" | "monthly" =
                "daily";

            if (vote.status === "active") {
                priority = 0.8;
                changeFrequency = "hourly";
            } else if (vote.status === "upcoming") {
                priority = 0.7;
                changeFrequency = "daily";
            } else if (vote.status === "past") {
                priority = 0.5;
                changeFrequency = "weekly";
            }

            return {
                url: `${SITE_URL}/vote/${vote.id}`,
                lastModified: new Date(vote.updated_at || vote.created_at),
                changeFrequency,
                priority,
            };
        });

        // 정적 URL과 동적으로 생성된 투표 URL 결합
        return [...allStaticUrls, ...voteUrls];
    } catch (error) {
        console.error("사이트맵 생성 중 오류:", error);
        // 오류 발생 시 정적 URL만 반환
        return allStaticUrls;
    }
}
