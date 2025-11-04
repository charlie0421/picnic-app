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
      onTokenCount: options.onTokenCount
    });

    // Some providers may wrap JSON or add stray characters; try to parse robustly
    const cleaned = content.trim().replace(/^```json\n?/i, '').replace(/\n?```$/i, '');
    return JSON.parse(cleaned) as T;
  } catch (error) {
    logError(error, { context: 'gpt-translate-json', targetLang });
    throw error;
  }
}


