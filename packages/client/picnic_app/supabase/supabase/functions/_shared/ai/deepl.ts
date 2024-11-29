import { logError } from '../utils.ts';
import { SupportedLanguage, TranslationResult } from '../types/openai.ts';

let deeplApiKey: string | undefined = undefined;

export function initializeDeepL(apiKey: string) {
    deeplApiKey = apiKey;
}

export function getDeepLApiKey(): string {
    if (!deeplApiKey) {
        deeplApiKey = Deno.env.get('DEEPL_API_KEY');
    }

    if (!deeplApiKey) {
        throw new Error('DeepL API key not configured');
    }

    return deeplApiKey;
}

export async function translateText(
    text: string,
    targetLang: SupportedLanguage,
    sourceLang: SupportedLanguage = 'ko',
): Promise<string> {
    try {
        const response = await fetch('https://api-free.deepl.com/v2/translate', {
            method: 'POST',
            headers: {
                'Authorization': `DeepL-Auth-Key ${getDeepLApiKey()}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                text: [text],
                target_lang: targetLang.toUpperCase(),
                source_lang: sourceLang.toUpperCase(),
            }),
        });

        if (!response.ok) {
            throw new Error(`DeepL API error: ${response.statusText}`);
        }

        const data = await response.json() as TranslationResult;
        return data.translations[0].text;
    } catch (error) {
        logError(error, {
            context: 'deepl-translation',
            text,
            targetLang,
            sourceLang,
        });
        throw error;
    }
}

export async function translateBatch(
    texts: string[],
    targetLang: SupportedLanguage,
    sourceLang: SupportedLanguage = 'ko',
): Promise<string[]> {
    try {
        const response = await fetch('https://api.deepl.com/v2/translate', {
            method: 'POST',
            headers: {
                'Authorization': `DeepL-Auth-Key ${getDeepLApiKey()}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                text: texts,
                target_lang: targetLang.toUpperCase(),
                source_lang: sourceLang.toUpperCase(),
            }),
        });

        if (!response.ok) {
            throw new Error(`DeepL API error: ${response.statusText}`);
        }

        const data = await response.json() as TranslationResult;
        return data.translations.map((t) => t.text);
    } catch (error) {
        logError(error, {
            context: 'deepl-batch-translation',
            texts,
            targetLang,
            sourceLang,
        });
        throw error;
    }
}
