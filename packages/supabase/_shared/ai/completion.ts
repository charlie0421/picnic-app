import { PromptService } from '../services/prompt.ts';
import { OpenAIError } from './errors.ts';
import type { TokenUsage } from '../types/openai.ts';
import { createChatCompletion } from './openai.ts';

export async function generateCompletion(
    promptName: string,
    variables: Record<string, any>,
): Promise<any> {
    const promptService = PromptService.getInstance();
    const startTime = Date.now();
    let tokenUsage: number | null = null;

    try {
        const prompt = await promptService.getPrompt(promptName);
        if (!prompt) {
            throw new Error(`Prompt not found: ${promptName}`);
        }

        const renderedPrompt = await promptService.renderPrompt(prompt, variables);

        console.log('prompt.model_config:', prompt.model_config);

        const response = await createChatCompletion(renderedPrompt, {
            ...prompt.model_config,
            onTokenCount: (usage) => {
                tokenUsage = usage;
            },
        });

        // 프롬프트 사용 로그 기록
        promptService.logPromptUsage({
            prompt_id: prompt.id,
            variables,
            response: response,
            execution_time_ms: Date.now() - startTime,
            token_count: tokenUsage ?? 0,
        }).catch(() => {}); // 로깅 실패는 무시

        return response;
    } catch (error) {
        const errorLog = {
            prompt_id: promptName,
            variables,
            response: null,
            execution_time_ms: Date.now() - startTime,
            token_count: tokenUsage ?? 0,
            error: error instanceof Error ? error.message : 'Unknown error',
        };

        // 에러 로그 기록
        promptService.logPromptUsage(errorLog).catch(() => {});
        throw error;
    }
}
