export interface CompatibilityResult {
    compatibility_score: number;
    compatibility_summary: string;
    details: {
        style: {
            idol_style: string;
            user_style: string;
            couple_style: string;
        };
        activities: {
            recommended: string[];
            description: string;
        };
    };
    tips: string[];
}

export interface Compatibility {
    id: string;
    idol_birth_date: string;
    user_birth_date: string;
    user_birth_time: string | null;
    gender: string;
    artist_id: string;
    artist: {
        name: string;
    };
}
