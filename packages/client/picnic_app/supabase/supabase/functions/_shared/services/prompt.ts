import { getSupabaseClient } from '../database.ts';
import { logError } from '../index.ts';
import type { Prompt, PromptUsageLog } from '../types/prompt.ts';

export class PromptService {
    private static instance: PromptService;
    private supabase;
    private promptCache: Map<string, { prompt: Prompt; expiry: number }>;
    private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

    private constructor() {
        this.supabase = getSupabaseClient();
        this.promptCache = new Map();
    }

    public static getInstance(): PromptService {
        if (!PromptService.instance) {
            PromptService.instance = new PromptService();
        }
        return PromptService.instance;
    }

    async getPrompt(name: string): Promise<Prompt | null> {
        const cached = this.promptCache.get(name);
        const now = Date.now();

        if (cached && cached.expiry > now) {
            return cached.prompt;
        }

        const prompt = await this.fetchPromptFromDB(name);

        if (prompt) {
            this.promptCache.set(name, {
                prompt,
                expiry: now + this.CACHE_TTL,
            });
        }

        return prompt;
    }

    async renderPrompt(prompt: Prompt, variables: Record<string, any>): Promise<string> {
        try {
            // 필수 변수 검증
            /*            const missingVars = prompt.variables.filter((v) => !(v in variables));
            console.log('missingVars:', missingVars);
            if (missingVars.length > 0) {
                throw new Error(`Missing required variables: ${missingVars.join(', ')}`);
            }
            */
            let renderedTemplate = prompt.template;

            // 템플릿의 변수들을 실제 값으로 대체
            for (const [key, value] of Object.entries(variables)) {
                const regex = new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, 'g');
                renderedTemplate = renderedTemplate.replace(regex, String(value));
            }

            return renderedTemplate;
        } catch (error) {
            logError(error, {
                context: 'prompt-service',
                action: 'render-prompt',
                promptId: prompt.id,
                variables,
            });
            throw error;
        }
    }

    async logPromptUsage(log: PromptUsageLog): Promise<void> {
        try {
            const { error } = await this.supabase
                .from('prompt_usage_logs')
                .insert({
                    ...log,
                    created_at: new Date().toISOString(),
                });

            if (error) throw error;
        } catch (error) {
            // 로깅 실패는 조용히 처리
            logError(error, {
                context: 'prompt-service',
                action: 'log-usage',
                promptId: log.prompt_id,
            });
        }
    }

    async getActivePrompt(name: string): Promise<Prompt> {
        // 캐시 확인
        const cached = this.promptCache.get(name);
        const now = Date.now();

        if (cached && cached.expiry > now) {
            return cached.prompt;
        }

        // 데이터베이스에서 프롬프트 조회
        const { data, error } = await this.supabase
            .from('prompts')
            .select('*')
            .eq('name', name)
            .eq('is_active', true)
            .order('version', { ascending: false })
            .limit(1)
            .single();

        if (error) {
            throw new Error(`Failed to fetch prompt: ${error.message}`);
        }

        if (!data) {
            throw new Error(`No active prompt found for: ${name}`);
        }

        // 캐시 업데이트
        this.promptCache.set(name, {
            prompt: data,
            expiry: now + this.CACHE_TTL,
        });

        return data;
    }

    private async fetchPromptFromDB(name: string): Promise<Prompt | null> {
        console.log('Fetching prompt from DB:', name);
        try {
            const { data, error } = await this.supabase
                .from('prompts')
                .select('*')
                .eq('name', name)
                .eq('is_active', true)
                .order('version', { ascending: false })
                .limit(1)
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            logError(error, {
                context: 'prompt-service',
                action: 'fetch-prompt',
                promptName: name,
            });
            throw error;
        }
    }
}
