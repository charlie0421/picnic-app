import { SupportedLanguage } from './openai.ts';

export interface FortuneTelling {
    id: string; // UUID
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

export interface FortuneTellingI18n extends FortuneTelling {
    fortune_id: string; // 참조하는 fortune_telling의 UUID
    language: SupportedLanguage;
}

export interface MonthlyFortune {
    month: number;
    summary: string;
    honor: string;
    career: string;
    health: string;
}

export interface Aspects {
    career: string;
    honor: string;
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
