import OpenAI from 'https://esm.sh/openai';
import { logError } from '../utils.ts';
import { ChatCompletionOptions, OpenAIConfig } from '../types/openai.ts';
import { OpenAIError } from './errors.ts';

let openaiInstance: OpenAI | null = null;

export function getOpenAIClient(config?: OpenAIConfig): OpenAI {
    const apiKey = config?.apiKey || Deno.env.get('OPENAI_COMPATIBILITY_API_KEY');

    if (!apiKey) {
        throw new OpenAIError(
            'OpenAI API 키가 설정되지 않았습니다. 관리자에게 문의해주세요.',
            'OPENAI_MISSING_KEY',
            401,
            false,
        );
    }

    if (!openaiInstance || config?.apiKey) {
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

        // 토큰 사용량 디버깅
        console.log('Token usage:', {
            total_tokens: completion.usage?.total_tokens,
            prompt_tokens: completion.usage?.prompt_tokens,
            completion_tokens: completion.usage?.completion_tokens,
        });

        if (options.onTokenCount && completion.usage?.total_tokens) {
            options.onTokenCount(completion.usage.total_tokens);
        }

        return completion.choices[0].message.content || '';
    } catch (error) {
        logError(error, {
            context: 'openai-chat-completion',
            prompt,
            options: { ...options, onTokenCount: undefined },
        });

        // API 키 관련 오류
        if (error instanceof Error) {
            const message = error.message?.toLowerCase() || '';

            if (message.includes('api key')) {
                throw new OpenAIError(
                    'API 키가 올바르지 않습니다. 관리자에게 문의해주세요.',
                    'OPENAI_INVALID_KEY',
                    401,
                    false,
                );
            }

            // Rate limit 오류
            if (message.includes('rate limit')) {
                throw new OpenAIError(
                    '잠시 요청이 많아 처리가 지연되고 있습니다. 잠시 후 다시 시도해주세요.',
                    'OPENAI_RATE_LIMIT',
                    429,
                    true,
                );
            }

            // 모델 관련 오류
            if (message.includes('model')) {
                throw new OpenAIError(
                    'AI 모델 설정에 문제가 있습니다. 관리자에게 문의해주세요.',
                    'OPENAI_MODEL_ERROR',
                    400,
                    false,
                );
            }

            // 컨텍스트 길이 초과
            if (message.includes('maximum context length')) {
                throw new OpenAIError(
                    '입력 내용이 너무 깁니다. 더 짧게 작성해주세요.',
                    'OPENAI_CONTEXT_LENGTH',
                    400,
                    false,
                );
            }
        }

        // 기타 알 수 없는 오류
        throw new OpenAIError(
            'AI 서비스 연결에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
            'OPENAI_UNKNOWN_ERROR',
            500,
            true,
        );
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

        if (error instanceof Error && error.message?.toLowerCase().includes('api key')) {
            throw new OpenAIError(
                'Moderation API 키가 올바르지 않습니다. 관리자에게 문의해주세요.',
                'OPENAI_MODERATION_KEY_ERROR',
                401,
                false,
            );
        }

        throw new OpenAIError(
            'Moderation 서비스 연결에 문제가 발생했습니다.',
            'OPENAI_MODERATION_ERROR',
            500,
            true,
        );
    }
}
