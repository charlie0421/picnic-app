export interface Compatibility {
    id: string;
    user_id: string;
    idol_birth_date: string;
    user_birth_date: string;
    user_birth_time: string | null;
    gender: string;
    artist_id: string;
    artist?: {
        name: string;
        gender: string;
    };
    details?: {
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
    tips?: string[];
    score?: number;
}
