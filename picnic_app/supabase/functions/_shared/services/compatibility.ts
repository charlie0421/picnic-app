import { getSupabaseClient } from '../database.ts';
import { createChatCompletion } from '../ai/openai.ts';
import { SUPPORTED_LANGUAGES } from '../types/openai.ts';
import { formatDate, logError } from '../utils.ts';
import { PromptService } from './prompt.ts';
export class CompatibilityService {
  supabase;
  promptService;
  constructor(){
    this.supabase = getSupabaseClient();
    this.promptService = PromptService.getInstance();
  }
  async existSimilarResults(compatibility) {
    try {
      const { data: similarResults, error } = await this.supabase.from('compatibility_results').select().eq('artist_id', compatibility.artist_id).eq('idol_birth_date', compatibility.idol_birth_date).eq('user_birth_time', compatibility.user_birth_time).eq('gender', compatibility.gender).eq('status', 'completed');
      if (error) throw error;
      return similarResults;
    } catch (error) {
      logError(error, {
        context: 'existSimilarResults',
        compatibility
      });
      throw error;
    }
  }
  async updateCompleted(compatibilityId) {
    try {
      const { data: updatedResult, error } = await this.supabase.from('compatibility_results').update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        error_message: null
      }).eq('id', compatibilityId).select().single();
      if (error) throw error;
      return updatedResult;
    } catch (error) {
      logError(error, {
        context: 'update-compatibility',
        compatibilityId
      });
      throw error;
    }
  }
  async generateAndStoreTranslations(compatibilityId, result) {
    // DeepL 제거로 인해 기존 선번역 저장 로직을 일시 비활성화합니다.
    // 이후 GPT 번역 지연 로딩/선계산 경로로 대체됩니다.
    return;
  }
  async generateNewResults(compatibility) {
    try {
      const prompt = await this.promptService.getActivePrompt('compatibility_analysis');
      // 변수 준비
      const variables = {
        artist_name: compatibility.artist.name,
        idol_birth_date: formatDate(compatibility.idol_birth_date),
        idol_gender: compatibility.artist.gender,
        user_birth_date: formatDate(compatibility.user_birth_date),
        user_birth_time: compatibility.user_birth_time || '미상',
        gender: compatibility.gender
      };
      // 프롬프트 템플릿에 변수 적용
      const renderedPrompt = this.renderTemplate(prompt.template, variables);
      const startTime = Date.now();
      let tokenCount;
      // ChatCompletion 호출
      const response = await createChatCompletion(renderedPrompt, {
        ...prompt.model_config,
        onTokenCount: (totalTokens)=>{
          tokenCount = totalTokens;
        }
      });
      console.log('Response:', response);
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
        token_count: tokenCount
      });
      // 1/10000 확률로 100점, 나머지는 0-99점 사이의 랜덤 값
      result.score = Math.random() < 0.0001 ? 100 : Math.floor(Math.random() * 100);
      // 새로운 결과를 먼저 데이터베이스에 삽입
      const { data: insertedResult, error: insertError } = await this.supabase.from('compatibility_results').update({
        score: result.score,
        details: result.details,
        tips: result.tips
      }).eq('id', compatibility.id).select().single();
      if (insertError) throw insertError;
      // 번역 선계산 분기: lazy(기본)에서는 수행하지 않음
      const mode = (Deno.env.get('TRANSLATION_MODE') || 'lazy').toLowerCase();
      if (mode === 'eager' || mode === 'hybrid') {
        await this.generateAndStoreTranslations(compatibility.id, result);
      }
      return insertedResult;
    } catch (error) {
      logError(error, {
        context: 'compatibility-generation',
        compatibility
      });
      throw error;
    }
  }
  async copyExistingResults(compatibility, compatibility_id) {
    try {
      console.log('similarResults', compatibility);
      const { data: newResult, error: resultError } = await this.supabase.from('compatibility_results').update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        score: compatibility.score,
        details: compatibility.details,
        tips: compatibility.tips
      }).eq('id', compatibility_id).select('*, details, tips').single();
      console.log('newResult', newResult);
      if (resultError) throw resultError;
      // i18n 데이터 복사
      await this.copyI18nData(compatibility.id, newResult.id);
      // 복사된 결과임을 표시
      return {
        ...newResult,
        is_copied: true
      };
    } catch (error) {
      logError(error, {
        context: 'copy-existing-results',
        compatibility_id: compatibility.id
      });
      throw error;
    }
  }
  async copyI18nData(sourceId, targetId) {
    const { data: sourceI18n, error: i18nFetchError } = await this.supabase.from('compatibility_results_i18n').select('*').eq('compatibility_id', sourceId);
    if (i18nFetchError) throw i18nFetchError;
    if (sourceI18n && sourceI18n.length > 0) {
      const newI18nEntries = sourceI18n.map((entry)=>({
          compatibility_id: targetId,
          language: entry.language,
          score: entry.score,
          compatibility_summary: entry.compatibility_summary,
          score_title: entry.score_title,
          details: entry.details,
          tips: entry.tips
        }));
      const { error: i18nInsertError } = await this.supabase.from('compatibility_results_i18n').insert(newI18nEntries);
      if (i18nInsertError) {
        console.error('Failed to copy i18n results:', i18nInsertError);
        throw i18nInsertError;
      }
    }
  }
  renderTemplate(template, variables) {
    let renderedTemplate = template;
    for (const [key, value] of Object.entries(variables)){
      const regex = new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, 'g');
      renderedTemplate = renderedTemplate.replace(regex, value);
    }
    return renderedTemplate;
  }
  validateResult(result) {
    if (!result) return false;
    // tips 배열 검증
    const hasTips = Array.isArray(result.tips) && result.tips.length === 3;
    // details 구조 검증
    const hasValidDetails = result.details && result.details.style && typeof result.details.style === 'object' && result.details.activities && typeof result.details.activities === 'object' && Array.isArray(result.details.activities.recommended);
    return hasTips && hasValidDetails;
  }
  async getDescriptions(score) {
    const { data: descriptions, error } = await this.supabase.from('compatibility_score_descriptions').select().eq('score', score);
    if (error) throw error;
    return descriptions;
  }
}
