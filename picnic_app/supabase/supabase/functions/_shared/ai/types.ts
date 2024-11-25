export const SUPPORTED_LANGUAGES = ['ko', 'en', 'ja', 'zh'] as const;
export type SupportedLanguage = typeof SUPPORTED_LANGUAGES[number];

export interface TranslationResult {
    translations: Array<{ text: string }>;
}

export interface OpenAIConfig {
    apiKey?: string;
    model?: string;
    temperature?: number;
}

export interface ChatCompletionOptions {
    systemPrompt?: string;
    temperature?: number;
    model?: string;
    responseFormat?: 'text' | 'json_object';
}
