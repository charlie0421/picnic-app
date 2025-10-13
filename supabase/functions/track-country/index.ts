// @ts-nocheck
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

function getClientIp(req: Request): string {
  const xf = req.headers.get('x-forwarded-for') || req.headers.get('X-Forwarded-For') || '';
  if (xf) {
    const parts = xf.split(',').map((s) => s.trim()).filter(Boolean);
    if (parts.length > 0) return parts[0];
  }
  return req.headers.get('x-real-ip') || req.headers.get('X-Real-IP') || 'unknown';
}

function getCountryFromHeaders(req: Request): string | null {
  // Cloudflare / Vercel forward country headers when available
  const cfCountry = req.headers.get('cf-ipcountry') || req.headers.get('CF-IPCountry');
  if (cfCountry && cfCountry.length === 2) return cfCountry.toUpperCase();
  return null;
}

async function lookupCountryByIp(ip: string): Promise<string | null> {
  // Avoid calling external API for private/unknown IPs
  if (!ip || ip === 'unknown' || ip.startsWith('127.') || ip.startsWith('10.') || ip.startsWith('192.168.') || ip.startsWith('172.16.')) {
    return null;
  }
  try {
    // Free, rate-limited IP info source (can be swapped to paid provider)
    const res = await fetch(`https://ipapi.co/${encodeURIComponent(ip)}/country/`, { timeout: 1500 });
    if (!res.ok) return null;
    const text = (await res.text()).trim();
    if (text && text.length === 2) return text.toUpperCase();
  } catch (_) {
    // ignore
  }
  return null;
}

type Payload = {
  source?: string; // 'login' | 'token_refresh' | 'manual'
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } }
    }
  );

  try {
    let source: string = 'unknown';
    try {
      const body = await req.json();
      if (body && typeof body.source === 'string') source = body.source;
    } catch (_) {
      // no body
    }

    const { data: authRes } = await supabase.auth.getUser();
    const userId = authRes?.user?.id ?? null;
    if (!userId) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 });
    }

    const ip = getClientIp(req);
    let country = getCountryFromHeaders(req);
    if (!country) {
      country = await lookupCountryByIp(ip);
    }

    if (!country) {
      return new Response(JSON.stringify({ ok: true, skipped: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });
    }

    // 1) user_profiles.country_code 업데이트 (존재 시만 변경)
    await supabase.from('user_profiles').update({ country_code: country }).eq('id', userId);

    // 2) 이벤트 로그 insert
    await supabase.from('user_country_events').insert({ user_id: userId, country_code: country, source: source || 'unknown' });

    return new Response(JSON.stringify({ ok: true, country }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });
  } catch (e) {
    console.error('[track-country] unexpected', String(e?.message || e));
    return new Response(JSON.stringify({ error: 'unexpected' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 });
  }
});



