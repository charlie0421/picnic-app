// 사이트의 모든 정적 페이지 경로 목록
export const STATIC_PAGES = [
    // 메인 페이지
    { path: "", priority: 1.0, changeFreq: "daily" },

    // 기본 페이지
    { path: "vote", priority: 0.9, changeFreq: "hourly" },
    { path: "about", priority: 0.8, changeFreq: "monthly" },
    { path: "terms", priority: 0.7, changeFreq: "monthly" },
    { path: "privacy", priority: 0.7, changeFreq: "monthly" },
    { path: "faq", priority: 0.8, changeFreq: "weekly" },
    { path: "contact", priority: 0.7, changeFreq: "monthly" },

    // 사용자 관련 페이지
    { path: "login", priority: 0.6, changeFreq: "monthly" },
    { path: "register", priority: 0.6, changeFreq: "monthly" },

    // 추가 서비스 페이지
    { path: "photoframe", priority: 0.8, changeFreq: "weekly" },
    { path: "artists", priority: 0.9, changeFreq: "daily" },
    { path: "events", priority: 0.9, changeFreq: "daily" },
];

// 도메인 정보
export const SITE_URL = "https://www.picnic.fan";
