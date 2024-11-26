import { getSupabaseClient } from '../database.ts';
import { createChatCompletion } from '../ai/openai.ts';
import { translateBatch, translateText } from '../ai/deepl.ts';
import { SUPPORTED_LANGUAGES, SupportedLanguage } from '../types/openai.ts';
import { formatDate, logError } from '../utils.ts';
import { PromptService } from './prompt.ts';
import type { Compatibility, CompatibilityResult } from '../types/compatibility.ts';

export class CompatibilityService {
    private supabase;
    private promptService;

    constructor() {
        this.supabase = getSupabaseClient();
        this.promptService = PromptService.getInstance();
    }

    async getOrGenerateResults(compatibility: Compatibility): Promise<CompatibilityResult> {
        try {
            // 동일한 조합의 기존 결과 검색
            const query = this.supabase
                .from('compatibility_results')
                .select('compatibility_score, compatibility_summary, details, tips')
                .eq('artist_id', compatibility.artist_id)
                .eq('idol_birth_date', compatibility.idol_birth_date)
                .eq('user_birth_date', compatibility.user_birth_date)
                .eq('gender', compatibility.gender)
                .eq('status', 'completed')
                .neq('id', compatibility.id)
                .order('completed_at', { ascending: false })
                .limit(1);

            const { data: existingResults, error } = await (
                compatibility.user_birth_time === null
                    ? query.is('user_birth_time', null)
                    : query.eq('user_birth_time', compatibility.user_birth_time)
            );

            if (error) throw error;

            // 기존 결과가 있으면 재사용
            if (existingResults?.length > 0) {
                console.log('Reusing existing result');
                return existingResults[0];
            }

            // 새로운 결과 생성
            console.log('Generating new result');
            return await this.generateNewResults(compatibility);
        } catch (error) {
            logError(error, {
                context: 'compatibility-result',
                compatibility,
            });
            throw error;
        }
    }

    async updateResults(
        compatibilityId: string,
        result: CompatibilityResult,
    ): Promise<void> {
        try {
            const { error } = await this.supabase
                .from('compatibility_results')
                .update({
                    ...result,
                    status: 'completed',
                    completed_at: new Date().toISOString(),
                    error_message: null,
                })
                .eq('id', compatibilityId);

            if (error) throw error;
        } catch (error) {
            logError(error, {
                context: 'update-compatibility',
                compatibilityId,
                result,
            });
            throw error;
        }
    }

    async generateAndStoreTranslations(
        compatibilityId: string,
        result: CompatibilityResult,
    ): Promise<void> {
        try {
            // 기존 번역 삭제
            await this.supabase
                .from('compatibility_results_i18n')
                .delete()
                .eq('compatibility_id', compatibilityId);

            // 각 언어별 번역 생성 및 저장
            for (const lang of SUPPORTED_LANGUAGES) {
                try {
                    const translatedResult = await this.translateResult(result, lang);

                    await this.supabase
                        .from('compatibility_results_i18n')
                        .insert({
                            compatibility_id: compatibilityId,
                            language: lang,
                            ...translatedResult,
                            created_at: new Date().toISOString(),
                            updated_at: new Date().toISOString(),
                        });

                    console.log(`Successfully saved ${lang} translation`);
                } catch (langError) {
                    logError(langError, {
                        context: 'translation-processing',
                        language: lang,
                        compatibilityId,
                    });
                    // 개별 언어 처리 실패 시 다음 언어로 계속 진행
                }
            }
        } catch (error) {
            logError(error, {
                context: 'translations',
                compatibilityId,
            });
            throw error;
        }
    }

    private async generateNewResults(compatibility: Compatibility): Promise<CompatibilityResult> {
        try {
            const prompt = await this.promptService.getActivePrompt('compatibility_analysis');

            // 변수 준비
            const variables = {
                artist_name: compatibility.artist.name,
                idol_birth_date: formatDate(compatibility.idol_birth_date),
                user_birth_date: formatDate(compatibility.user_birth_date),
                user_birth_time: compatibility.user_birth_time || '미상',
                gender: compatibility.gender,
            };

            // 프롬프트 템플릿에 변수 적용
            const renderedPrompt = this.renderTemplate(prompt.template, variables);

            const startTime = Date.now();
            let tokenCount: number | undefined;

            // ChatCompletion 호출
            const response = await createChatCompletion(renderedPrompt, {
                ...prompt.model_config,
                onTokenCount: (totalTokens: number) => {
                    tokenCount = totalTokens;
                },
            });

            const result = JSON.parse(response) as CompatibilityResult;

            if (!this.validateResult(result)) {
                throw new Error('Invalid compatibility result format');
            }

            // 프롬프트 사용 로깅
            await this.promptService.logPromptUsage({
                prompt_id: prompt.id,
                variables,
                response: result,
                execution_time_ms: Date.now() - startTime,
                token_count: tokenCount,
            });

            return result;
        } catch (error) {
            logError(error, {
                context: 'compatibility-generation',
                compatibility,
            });
            throw error;
        }
    }

    private renderTemplate(template: string, variables: Record<string, string>): string {
        let renderedTemplate = template;
        for (const [key, value] of Object.entries(variables)) {
            const regex = new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, 'g');
            renderedTemplate = renderedTemplate.replace(regex, value);
        }
        return renderedTemplate;
    }

    private validateResult(result: any): result is CompatibilityResult {
        return (
            result &&
            typeof result.compatibility_score === 'number' &&
            typeof result.compatibility_summary === 'string' &&
            Array.isArray(result.tips) &&
            result.tips.length === 3 &&
            result.details?.style &&
            result.details?.activities?.recommended &&
            Array.isArray(result.details.activities.recommended)
        );
    }

    private async translateResult(
        result: CompatibilityResult,
        targetLang: SupportedLanguage,
    ): Promise<CompatibilityResult> {
        if (targetLang === 'ko') return result;

        const translatedDetails = {
            style: {
                idol_style: await translateText(result.details.style.idol_style, targetLang),
                user_style: await translateText(result.details.style.user_style, targetLang),
                couple_style: await translateText(result.details.style.couple_style, targetLang),
            },
            activities: {
                recommended: await translateBatch(
                    result.details.activities.recommended,
                    targetLang,
                ),
                description: await translateText(result.details.activities.description, targetLang),
            },
        };

        return {
            ...result,
            compatibility_summary: await translateText(result.compatibility_summary, targetLang),
            details: translatedDetails,
            tips: await translateBatch(result.tips, targetLang),
        };
    }
}
