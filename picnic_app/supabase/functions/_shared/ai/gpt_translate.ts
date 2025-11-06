import { logError } from '../utils.ts';
import { createChatCompletion } from './openai.ts';

type TranslateOptions = {
  model?: string;
  temperature?: number;
  onTokenCount?: (n: number) => void;
};

/**
 * Translate a structured JSON object to a target language while preserving schema.
 * Only string fields should be translated; arrays/objects structure must be intact.
 */
export async function gptTranslateJson<T>(baseObject: T, targetLang: string, options: TranslateOptions = {}): Promise<T> {
  try {
    const startedAt = Date.now();
    let usedTokens = 0;
    const hasHangul = (v: unknown) => /[\u3131-\uD79D]/.test(JSON.stringify(v));
    const systemPrompt = [
      'You are a professional product translator.',
      'Translate ALL user-visible strings to the target language while strictly preserving the input JSON schema and keys.',
      'Do NOT add or remove fields. Keep arrays and objects structure identical.',
      'Return ONLY a valid JSON object. No markdown code fences.'
    ].join(' ');

    const userPrompt = [
      `Target language: ${targetLang}`,
      'Input JSON to translate:',
      JSON.stringify(baseObject)
    ].join('\n');

    const content = await createChatCompletion(userPrompt, {
      model: options.model || 'gpt-5',
      temperature: options.temperature ?? 0.2,
      responseFormat: 'json_object',
      systemPrompt,
      onTokenCount: (n: number) => {
        usedTokens = n;
        if (options.onTokenCount) options.onTokenCount(n);
      }
    });

    // Some providers may wrap JSON or add stray characters; try to parse robustly
    const cleaned = content.trim().replace(/^```json\n?/i, '').replace(/\n?```$/i, '');
    let parsed = JSON.parse(cleaned) as T;

    // If translation failed (still Hangul remains for non-ko), retry once with stricter instruction
    if (targetLang.toLowerCase() !== 'ko' && hasHangul(parsed)) {
      const forcePrompt = [
        systemPrompt,
        'CRITICAL: Replace ALL Korean Hangul characters with the target language. Absolutely no Hangul (가-힣) may remain in values.'
      ].join(' ');
      const retryContent = await createChatCompletion(userPrompt, {
        model: options.model || 'gpt-5',
        temperature: Math.max(0.3, (options.temperature ?? 0.2)),
        responseFormat: 'json_object',
        systemPrompt: forcePrompt,
        onTokenCount: (n: number) => { usedTokens = n; if (options.onTokenCount) options.onTokenCount(n); }
      });
      const retryClean = retryContent.trim().replace(/^```json\n?/i, '').replace(/\n?```$/i, '');
      parsed = JSON.parse(retryClean) as T;
    }
    const elapsed = Date.now() - startedAt;
    console.log('gptTranslateJson metrics:', { ms: elapsed, targetLang, tokens: usedTokens, size: JSON.stringify(baseObject).length });
    return parsed;
  } catch (error) {
    logError(error, { context: 'gpt-translate-json', targetLang });
    throw error;
  }
}


