export interface FortuneTelling {
    id?: string;
    artist_id: number;
    year: number;
    overall_luck: string;
    monthly_fortunes: MonthlyFortune[];
    aspects: Aspects;
    lucky: Lucky;
    advice: string[];
    created_at?: string;
    updated_at?: string;
}

export interface MonthlyFortune {
    month: number;
    summary: string;
    love: string;
    career: string;
    health: string;
}

export interface Aspects {
    career: string;
    love: string;
    health: string;
    relationships: string;
    finances: string;
}

export interface Lucky {
    colors: string[];
    numbers: number[];
    days: string[];
    directions: string[];
}

export interface Artist {
    name: string;
    yy: number;
    mm: number;
    dd: number;
    gender: string;
}
