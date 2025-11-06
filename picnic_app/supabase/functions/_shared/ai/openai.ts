// @ts-ignore: Deno URL import
import OpenAI from 'https://esm.sh/openai';
import { logError } from '../utils.ts';
import { OpenAIError } from './errors.ts';
// deno-lint-ignore no-explicit-any
declare const Deno: any;
let openaiInstance: any = null;
export function getOpenAIClient(config) {
  const apiKey = (config as any)?.apiKey || Deno.env.get('OPENAI_COMPATIBILITY_API_KEY');
  if (!apiKey) {
    throw new OpenAIError('OpenAI API 키가 설정되지 않았습니다. 관리자에게 문의해주세요.', 'OPENAI_MISSING_KEY', 401, false);
  }
  if (!openaiInstance || (config as any)?.apiKey) {
    openaiInstance = new OpenAI({
      apiKey
    });
  }
  return openaiInstance;
}
export async function createChatCompletion(prompt, options = {}) {
  const openai: any = getOpenAIClient(undefined as any);
  const opts: any = options || {};
  const startedAt = Date.now();
  const makeCall = async () => {
    const completion = await openai.chat.completions.create({
      model: opts.model || 'gpt-4o-mini',
      temperature: opts.temperature ?? 1,
      response_format: opts.responseFormat === 'json_object' ? { type: 'json_object' } : undefined,
      messages: [
        ...(opts.systemPrompt ? [{ role: 'system', content: opts.systemPrompt }] : []),
        { role: 'user', content: prompt }
      ]
    });
    const elapsed = Date.now() - startedAt;
    // 토큰/시간 로깅
    console.log('OpenAI completion metrics:', {
      ms: elapsed,
      model: opts.model || 'gpt-4o-mini',
      total_tokens: completion.usage?.total_tokens,
      prompt_tokens: completion.usage?.prompt_tokens,
      completion_tokens: completion.usage?.completion_tokens
    });
    if (opts.onTokenCount && completion.usage?.total_tokens) {
      opts.onTokenCount(completion.usage.total_tokens);
    }
    return completion.choices[0].message.content || '';
  };
  try {
    try {
      return await makeCall();
    } catch (first) {
      // 단일 재시도 (레이트/일시적 오류)
      const msg = (first as any)?.message?.toLowerCase?.() || '';
      if (msg.includes('rate limit') || msg.includes('timeout') || msg.includes('temporarily')) {
        await new Promise(r => setTimeout(r, 800));
        return await makeCall();
      }
      throw first;
    }
  } catch (error) {
    logError(error, {
      context: 'openai-chat-completion',
      prompt,
      options: { ...opts, onTokenCount: undefined }
    });
    if (error instanceof Error) {
      const message = error.message?.toLowerCase() || '';
      if (message.includes('api key')) {
        throw new OpenAIError('API 키가 올바르지 않습니다. 관리자에게 문의해주세요.', 'OPENAI_INVALID_KEY', 401, false);
      }
      if (message.includes('rate limit')) {
        throw new OpenAIError('잠시 요청이 많아 처리가 지연되고 있습니다. 잠시 후 다시 시도해주세요.', 'OPENAI_RATE_LIMIT', 429, true);
      }
      if (message.includes('model')) {
        throw new OpenAIError('AI 모델 설정에 문제가 있습니다. 관리자에게 문의해주세요.', 'OPENAI_MODEL_ERROR', 400, false);
      }
      if (message.includes('maximum context length')) {
        throw new OpenAIError('입력 내용이 너무 깁니다. 더 짧게 작성해주세요.', 'OPENAI_CONTEXT_LENGTH', 400, false);
      }
    }
    throw new OpenAIError('AI 서비스 연결에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.', 'OPENAI_UNKNOWN_ERROR', 500, true);
  }
}
export async function performModeration(text) {
  const openai = getOpenAIClient({
    apiKey: Deno.env.get('OPENAI_MODERATOR_API_KEY')
  });
  try {
    const response = await openai.moderations.create({
      input: text
    });
    const result = response.results[0];
    const categories = Object.keys(result.categories).reduce((acc, key)=>{
      acc[key] = result.categories[key];
      return acc;
    }, {});
    const category_scores = Object.keys(result.category_scores).reduce((acc, key)=>{
      acc[key] = result.category_scores[key];
      return acc;
    }, {});
    return {
      ...result,
      categories,
      category_scores
    };
  } catch (error) {
    logError(error, {
      context: 'openai-moderation',
      text
    });
    if (error instanceof Error && error.message?.toLowerCase().includes('api key')) {
      throw new OpenAIError('Moderation API 키가 올바르지 않습니다. 관리자에게 문의해주세요.', 'OPENAI_MODERATION_KEY_ERROR', 401, false);
    }
    throw new OpenAIError('Moderation 서비스 연결에 문제가 발생했습니다.', 'OPENAI_MODERATION_ERROR', 500, true);
  }
}
