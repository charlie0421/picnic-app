// Setup type definitions for built-in Supabase Runtime APIs
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

import { createCorsHeaders } from '../_shared/cors.ts';
import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts';
import { getSupabaseClient, } from '../_shared/database.ts';
import { logError } from '../_shared/utils.ts';
import { gptTranslateJson } from '../_shared/ai/gpt_translate.ts';
import { parseTranslationLanguages } from '../_shared/i18n/locales.ts';

// For type-checkers that don't pick up Deno types in this workspace
// deno-lint-ignore no-explicit-any
declare const Deno: any;

type RequestBody = {
  compatibility_id: string;
  language: string; // e.g., 'en', 'ja', 'zh', ...
};

Deno.serve(async (req) => {
  const origin = req.headers.get('origin') || '';
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: createCorsHeaders(origin, { allowedOrigins: ['*'] })
    });
  }

  const cors = createCorsHeaders(origin, { allowedOrigins: ['*'] });

  try {
    const startedAt = Date.now();
    if (req.method !== 'POST') {
      return createErrorResponse('Method not allowed', 405, 'METHOD_NOT_ALLOWED', {}, cors);
    }

    const body = (await req.json()) as RequestBody;
    const compatibilityId = body?.compatibility_id;
    const language = (body?.language || '').trim();
    if (!compatibilityId || !language) {
      return createErrorResponse('compatibility_id and language are required', 400, 'INVALID_PARAMS', {}, cors);
    }

    // 0) Validate language against allowed list (env overrideable)
    const allowed = parseTranslationLanguages();
    if (!allowed.includes(language)) {
      return createErrorResponse('Unsupported language', 400, 'UNSUPPORTED_LANGUAGE', { language, allowed }, cors);
    }

    const supabase: any = getSupabaseClient()!;

    // 1) Check if already exists
    const { data: existing, error: existErr } = await supabase
      .from('compatibility_results_i18n')
      .select('*')
      .eq('compatibility_id', compatibilityId)
      .eq('language', language)
      .limit(1)
      .maybeSingle();
    if (existErr) throw existErr;
    if (existing) {
      return createSuccessResponse({ ok: true, created: false, data: existing }, cors);
    }

    // 2) Load base (ko) result
    const { data: base, error: baseErr } = await supabase
      .from('compatibility_results')
      .select('*')
      .eq('id', compatibilityId)
      .limit(1)
      .single();
    if (baseErr || !base) throw baseErr || new Error('Base result not found');
    if (base.status !== 'completed') {
      throw new Error('Result is not ready');
    }

    // 3) Get descriptions for summary/title
    let summaryKo = '';
    let titleKo = '';
    try {
      const { data: descRows } = await supabase
        .from('compatibility_score_descriptions')
        .select('*')
        .eq('score', base.score)
        .limit(1);
      if (descRows && descRows.length > 0) {
        const row = descRows[0] as any;
        // 기존 컬럼 패턴: summary_ko, title_ko 등. ko가 없을 수 있어 안전 접근
        summaryKo = row.summary_ko || row.summary || '';
        titleKo = row.title_ko || row.title || '';
      }
    } catch {}

    const toTranslateMeta = { compatibility_summary: summaryKo, score_title: titleKo };
    const toTranslateBody = { details: base.details || {}, tips: base.tips || [] };

    // 4) Translate via GPT-5
    const [metaTranslated, bodyTranslated] = await Promise.all([
      gptTranslateJson<typeof toTranslateMeta>(toTranslateMeta, language, { model: 'gpt-5', temperature: 0.2 }),
      gptTranslateJson<typeof toTranslateBody>(toTranslateBody, language, { model: 'gpt-5', temperature: 0.2 })
    ]);

    const insertData = {
      compatibility_id: compatibilityId,
      language,
      score: base.score,
      compatibility_summary: metaTranslated.compatibility_summary || '',
      score_title: metaTranslated.score_title || '',
      details: (bodyTranslated as any).details,
      tips: (bodyTranslated as any).tips
    };

    const { data: upserted, error: upsertErr } = await supabase
      .from('compatibility_results_i18n')
      .insert(insertData)
      .select('*')
      .single();
    if (upsertErr) throw upsertErr;

    console.log('compatibility-i18n metrics:', {
      ms: Date.now() - startedAt,
      language,
      score: base.score,
      detailsSize: JSON.stringify(insertData.details || {}).length,
      tipsLen: Array.isArray(insertData.tips) ? insertData.tips.length : 0
    });

    return createSuccessResponse({ ok: true, created: true, data: upserted }, cors);
  } catch (error) {
    logError(error, { context: 'compatibility-i18n' });
    return createErrorResponse((error as any)?.message || 'Internal Error', 500, 'COMPATIBILITY_I18N_ERROR', { shouldRetry: true }, cors);
  }
});


