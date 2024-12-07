import { getSupabaseClient } from '../database.ts';
import { createChatCompletion } from '../ai/openai.ts';
import { translateBatch, translateText } from '../ai/deepl.ts';
import { SUPPORTED_LANGUAGES, SupportedLanguage } from '../types/openai.ts';
import { formatDate, logError } from '../utils.ts';
import { PromptService } from './prompt.ts';
import type { Compatibility } from '../types/compatibility.ts';

export class CompatibilityService {
    private supabase;
    private promptService;
    constructor() {
        this.supabase = getSupabaseClient();
        this.promptService = PromptService.getInstance();
    }

    async existSimilarResults(compatibility: Compatibility): Promise<boolean> {
        try {
            const { data: similarResults, error } = await this.supabase
                .from('compatibility_results')
                .select()
                .eq('artist_id', compatibility.artist_id)
                .eq('idol_birth_date', compatibility.idol_birth_date)
                .eq('user_birth_date', compatibility.user_birth_date)
                .eq('gender', compatibility.gender)
                .eq('status', 'completed');

            if (error) throw error;

            return similarResults.length > 0;
        } catch (error) {
            logError(error, {
                context: 'existSimilarResults',
                compatibility,
            });
            throw error;
        }
    }

    async updateCompleted(
        compatibilityId: string,
    ): Promise<Compatibility> {
        try {
            const score = Math.round(Math.random() * 100);

            const { data: updatedResult, error } = await this.supabase
                .from('compatibility_results')
                .update({
                    status: 'completed',
                    completed_at: new Date().toISOString(),
                    error_message: null,
                })
                .eq('id', compatibilityId).select().single();

            if (error) throw error;

            return updatedResult;
        } catch (error) {
            logError(error, {
                context: 'update-compatibility',
                compatibilityId,
            });
            throw error;
        }
    }

    async generateAndStoreTranslations(
        compatibilityId: string,
        result: Compatibility,
    ): Promise<void> {
        try {
            console.log('Generating translations for:', compatibilityId);
            const descriptions = await this.getDescriptions(result.score!);
            console.log('Descriptions:', descriptions);
            // 각 언어별 번역 생성 및 저장
            for (const lang of SUPPORTED_LANGUAGES) {
                try {
                    const translatedResult = await this.translateResult(result, lang);

                    const insertData = {
                        compatibility_id: compatibilityId,
                        language: lang,
                        score: result.score,
                        compatibility_summary: descriptions[0]['summary_' + lang],
                        score_title: descriptions[0]['title_' + lang],
                        details: translatedResult.details,
                        tips: translatedResult.tips,
                    };

                    const { error } = await this.supabase
                        .from('compatibility_results_i18n')
                        .insert(insertData);

                    if (error) {
                        console.error(`Insert error for ${lang}:`, error);
                        throw error;
                    }

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

    async generateNewResults(compatibility: Compatibility): Promise<Compatibility> {
        try {
            const prompt = await this.promptService.getActivePrompt('compatibility_analysis');

            // 변수 준비
            const variables = {
                artist_name: compatibility.artist!.name,
                idol_birth_date: formatDate(compatibility.idol_birth_date),
                idol_gender: compatibility.artist!.gender,
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

            const result = JSON.parse(response.replaceAll('`', '').replace('json', ''));

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

            result.score = Math.round(Math.random() * 100);

            await this.generateAndStoreTranslations(compatibility.id, result);

            return result;
        } catch (error) {
            logError(error, {
                context: 'compatibility-generation',
                compatibility,
            });
            throw error;
        }
    }

    async copyExistingResults(
        compatibility: Compatibility,
    ): Promise<Compatibility> {
        try {
            const { data: similarResults, error } = await this.supabase
                .from('compatibility_results')
                .select()
                .eq('artist_id', compatibility.artist_id)
                .eq('idol_birth_date', compatibility.idol_birth_date)
                .eq('user_birth_date', compatibility.user_birth_date)
                .eq('gender', compatibility.gender)
                .eq('status', 'completed')
                .order('created_at', { ascending: false })
                .limit(1)
                .single();

            if (error) throw error;

            const { data: newResult, error: resultError } = await this.supabase
                .from('compatibility_results')
                .update({
                    status: 'completed',
                    completed_at: new Date().toISOString(),
                    score: similarResults.score,
                    details: similarResults.details,
                    tips: similarResults.tips,
                })
                .eq('id', compatibility.id)
                .select('*, details, tips')
                .single();

            if (resultError) throw resultError;

            // i18n 데이터 복사
            await this.copyI18nData(similarResults.id, newResult.id);

            // 복사된 결과임을 표시
            return { ...newResult, is_copied: true };
        } catch (error) {
            logError(error, {
                context: 'copy-existing-results',
                compatibility_id: compatibility.id,
            });
            throw error;
        }
    }

    private async copyI18nData(sourceId: string, targetId: string): Promise<void> {
        const { data: sourceI18n, error: i18nFetchError } = await this.supabase
            .from('compatibility_results_i18n')
            .select('*')
            .eq('compatibility_id', sourceId);

        if (i18nFetchError) throw i18nFetchError;

        if (sourceI18n && sourceI18n.length > 0) {
            const newI18nEntries = sourceI18n.map((entry) => ({
                compatibility_id: targetId,
                language: entry.language,
                score: entry.score,
                compatibility_summary: entry.compatibility_summary,
                score_title: entry.score_title,
                details: entry.details,
                tips: entry.tips,
            }));

            const { error: i18nInsertError } = await this.supabase
                .from('compatibility_results_i18n')
                .insert(newI18nEntries);

            if (i18nInsertError) {
                console.error('Failed to copy i18n results:', i18nInsertError);
                throw i18nInsertError;
            }
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

    private async translateResult(
        result: Compatibility,
        targetLang: SupportedLanguage,
    ): Promise<Compatibility> {
        try {
            if (targetLang === 'ko') return result;

            // 기본 구조 확인 및 초기화
            const defaultDetails = {
                style: {
                    idol_style: '',
                    user_style: '',
                    couple_style: '',
                },
                activities: {
                    recommended: [],
                    description: '',
                },
            };

            // result.details가 없거나 필요한 구조가 없는 경우 기본값 사용
            const details = result.details || defaultDetails;
            const style = details.style || defaultDetails.style;
            const activities = details.activities || defaultDetails.activities;

            // 번역 실행
            const translatedDetails = {
                style: {
                    idol_style: await translateText(style.idol_style || '', targetLang),
                    user_style: await translateText(style.user_style || '', targetLang),
                    couple_style: await translateText(style.couple_style || '', targetLang),
                },
                activities: {
                    recommended: await translateBatch(
                        activities.recommended || [],
                        targetLang,
                    ),
                    description: await translateText(activities.description || '', targetLang),
                },
            };

            return {
                ...result,
                details: translatedDetails,
                tips: await translateBatch(result.tips || [], targetLang),
            };
        } catch (error) {
            logError(error, {
                context: 'translate-result',
                targetLang,
                resultId: result.id,
            });
            // 에러 발생 시 원본 결과 반환
            return result;
        }
    }

    private validateResult(result: any): result is Compatibility {
        if (!result) return false;

        // tips 배열 검증
        const hasTips = Array.isArray(result.tips) && result.tips.length === 3;

        // details 구조 검증
        const hasValidDetails = result.details &&
            result.details.style &&
            typeof result.details.style === 'object' &&
            result.details.activities &&
            typeof result.details.activities === 'object' &&
            Array.isArray(result.details.activities.recommended);

        return hasTips && hasValidDetails;
    }
    private async getDescriptions(score: number) {
        const { data: descriptions, error } = await this.supabase
            .from('compatibility_score_descriptions')
            .select()
            .eq('score', score);

        if (error) throw error;

        return descriptions;
    }
}
