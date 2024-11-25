import OpenAI from 'https://esm.sh/openai';
import { logError } from '../utils.ts';
import { ChatCompletionOptions, OpenAIConfig } from './types.ts';

let openaiInstance: OpenAI | null = null;

export function getOpenAIClient(config?: OpenAIConfig): OpenAI {
    const apiKey = config?.apiKey || Deno.env.get('OPENAI_API_KEY');

    if (!apiKey) {
        throw new Error('Missing OpenAI API key');
    }

    if (!openaiInstance) {
        openaiInstance = new OpenAI({ apiKey });
    }

    return openaiInstance;
}

export async function createChatCompletion(
    prompt: string,
    options: ChatCompletionOptions = {},
): Promise<string> {
    const openai = getOpenAIClient();

    try {
        const completion = await openai.chat.completions.create({
            model: options.model || 'gpt-4o-mini',
            temperature: options.temperature ?? 1,
            response_format: options.responseFormat === 'json_object'
                ? { type: 'json_object' }
                : undefined,
            messages: [
                ...(options.systemPrompt
                    ? [{ role: 'system' as const, content: options.systemPrompt }]
                    : []),
                { role: 'user' as const, content: prompt },
            ],
        });

        return completion.choices[0].message.content || '';
    } catch (error) {
        logError(error, {
            context: 'openai-chat-completion',
            prompt,
            options,
        });
        throw error;
    }
}

export interface ModerationResult {
    flagged: boolean;
    categories: Record<string, boolean>;
    category_scores: Record<string, number>;
}

export async function performModeration(text: string): Promise<ModerationResult> {
    const openai = getOpenAIClient({
        apiKey: Deno.env.get('OPENAI_MODERATOR_API_KEY'),
    });

    try {
        const response = await openai.moderations.create({ input: text });
        const result = response.results[0];
        const categories: Record<string, boolean> = Object.keys(result.categories).reduce(
            (acc, key) => {
                acc[key] = result.categories[key as keyof typeof result.categories];
                return acc;
            },
            {} as Record<string, boolean>,
        );
        const category_scores: Record<string, number> = Object.keys(result.category_scores).reduce(
            (acc, key) => {
                acc[key] = result.category_scores[key as keyof typeof result.category_scores];
                return acc;
            },
            {} as Record<string, number>,
        );
        return { ...result, categories, category_scores };
    } catch (error) {
        logError(error, { context: 'openai-moderation', text });
        throw error;
    }
}
