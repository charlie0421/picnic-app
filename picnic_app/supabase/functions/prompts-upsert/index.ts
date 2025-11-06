import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

import { createCorsHeaders } from '../_shared/cors.ts';
import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts';
import { getSupabaseClient } from '../_shared/database.ts';
import { logError } from '../_shared/utils.ts';

// deno-lint-ignore no-explicit-any
declare const Deno: any;

type UpsertBody = {
  name?: string;
  template?: string;
  model_config?: Record<string, unknown>;
  variables?: string[];
  category?: string;
  description?: string;
  tags?: string[];
};

const DEFAULT_NAME = 'compatibility_analysis';
const DEFAULT_MODEL_CONFIG = { model: 'gpt-5', temperature: 0.7, responseFormat: 'json_object' } as const;
const DEFAULT_VARIABLES = ['artist_name','idol_birth_date','user_birth_date','user_birth_time','gender'];
const DEFAULT_CATEGORY = 'compatibility';
const DEFAULT_TEMPLATE = `You are a compatibility analysis AI. Using the given variables, produce a JSON with keys: score (0-100), details { style { idol_style, user_style, couple_style }, activities { recommended[], description } }, tips [3 strings].`;

Deno.serve(async (req) => {
  const origin = req.headers.get('origin') || '';
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: createCorsHeaders(origin, { allowedOrigins: ['*'] }) });
  }

  const cors = createCorsHeaders(origin, { allowedOrigins: ['*'] });
  try {
    if (req.method !== 'POST') {
      return createErrorResponse('Method not allowed', 405, 'METHOD_NOT_ALLOWED', {}, cors);
    }

    const body = (await req.json().catch(() => ({}))) as UpsertBody;
    const name = (body.name || DEFAULT_NAME).trim();
    const template = (body.template || DEFAULT_TEMPLATE);
    const model_config = (body.model_config || DEFAULT_MODEL_CONFIG) as Record<string, unknown>;
    const variables = Array.isArray(body.variables) && body.variables.length > 0 ? body.variables : DEFAULT_VARIABLES;
    const category = (body.category || DEFAULT_CATEGORY);
    const description = body.description || null;
    const tags = body.tags || [];

    const supabase: any = getSupabaseClient();

    // Find current max version for name
    const { data: existing } = await supabase
      .from('prompts')
      .select('id, version, is_active')
      .eq('name', name)
      .order('version', { ascending: false })
      .limit(1);

    let nextVersion = 1;
    if (existing && existing.length > 0) {
      nextVersion = (existing[0].version || 0) + 1;
      // Deactivate current active
      if (existing[0].is_active) {
        await supabase.from('prompts').update({ is_active: false }).eq('id', existing[0].id);
      }
    }

    const { data: inserted, error: insertErr } = await supabase
      .from('prompts')
      .insert({
        name,
        template,
        variables,
        model_config,
        version: nextVersion,
        is_active: true,
        category,
        description,
        tags
      })
      .select('*')
      .single();

    if (insertErr) {
      throw insertErr;
    }

    return createSuccessResponse({ ok: true, data: inserted }, cors);
  } catch (error) {
    logError(error, { context: 'prompts-upsert' });
    return createErrorResponse((error as any)?.message || 'Internal Error', 500, 'PROMPTS_UPSERT_ERROR', { shouldRetry: true }, cors);
  }
});


