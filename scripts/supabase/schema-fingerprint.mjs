import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { promisify } from 'node:util';

import {
  PRODUCTION_PROJECT_REF,
  assertReadonlyTarget,
  redactError,
} from './assert-readonly-target.mjs';

const execFileAsync = promisify(execFile);
const ENDPOINT = `/v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`;

export const CATALOG_QUERY = `
with catalog_rows as (
  select 'table'::text as kind,
         n.nspname || '.' || c.relname as identity,
         concat_ws('|', c.relkind::text, c.relrowsecurity::text, c.relforcerowsecurity::text) as definition
    from pg_catalog.pg_class c
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind in ('r','p','v','m')
  union all
  select 'column',
         n.nspname || '.' || c.relname || '.' || a.attname,
         concat_ws('|', pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull::text,
                   coalesce(pg_catalog.pg_get_expr(d.adbin, d.adrelid), ''))
    from pg_catalog.pg_attribute a
    join pg_catalog.pg_class c on c.oid = a.attrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    left join pg_catalog.pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
   where n.nspname = 'public' and c.relkind in ('r','p','v','m')
     and a.attnum > 0 and not a.attisdropped
  union all
  select 'constraint',
         n.nspname || '.' || c.relname || '.' || con.conname,
         pg_catalog.pg_get_constraintdef(con.oid, true)
    from pg_catalog.pg_constraint con
    join pg_catalog.pg_class c on c.oid = con.conrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
  union all
  select 'index',
         n.nspname || '.' || c.relname || '.' || i.relname,
         pg_catalog.pg_get_indexdef(i.oid)
    from pg_catalog.pg_index x
    join pg_catalog.pg_class c on c.oid = x.indrelid
    join pg_catalog.pg_class i on i.oid = x.indexrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
  union all
  select 'policy',
         schemaname || '.' || tablename || '.' || policyname,
         concat_ws('|', permissive, array_to_string(roles, ','), cmd, coalesce(qual, ''), coalesce(with_check, ''))
    from pg_catalog.pg_policies
   where schemaname = 'public'
  union all
  select 'function',
         n.nspname || '.' || p.proname || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')',
         concat('extension=', coalesce(e.extname, ''), '|', pg_catalog.pg_get_functiondef(p.oid))
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    left join pg_catalog.pg_depend d
      on d.classid = 'pg_catalog.pg_proc'::pg_catalog.regclass
     and d.objid = p.oid and d.deptype = 'e'
    left join pg_catalog.pg_extension e on e.oid = d.refobjid
   where n.nspname = 'public'
  union all
  select 'trigger',
         n.nspname || '.' || c.relname || '.' || t.tgname,
         pg_catalog.pg_get_triggerdef(t.oid, true)
    from pg_catalog.pg_trigger t
    join pg_catalog.pg_class c on c.oid = t.tgrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and not t.tgisinternal
)
select coalesce(json_agg(catalog_rows order by kind, identity), '[]'::json) as rows
from catalog_rows`;

function hash(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function normalizeDefinition(value, kind) {
  const normalized = String(value ?? '')
    .replace(/^\s*--.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/"/g, '')
    .replace(/\b(?:public|extensions)\./g, '')
    .replace(/::(?:character varying|text)(?:\[\])?/gi, '')
    .replace(/\(('(?:''|[^'])*')\)/g, '$1')
    .replace(/\(\(ARRAY\[/gi, '(ARRAY[')
    .replace(/\]\)\)/g, '])')
    .replace(/ANY \(ARRAY\[([^\]]]*)\]\)+/gi, 'ANY (ARRAY[$1])')
    .replace(/\s+/g, ' ')
    .trim();
  return kind === 'policy' ? normalized.replace(/[()]/g, '') : normalized;
}

export function isAllowedPlatformRow(row) {
  const definition = String(row?.definition ?? '');
  return (
    /^extension=[^|]+\|/i.test(definition) ||
    /^public\.cs_4_11_/i.test(String(row?.identity ?? '')) ||
    /^(?:public\.qna_messages\.alarm-qna-message|public\.vote_item_request_users\.alarm-artist-request)$/.test(
      String(row?.identity ?? ''),
    ) ||
    /\bsupabase_functions\b/i.test(definition) ||
    /\b(?:net\.http_post|http_request|functions\/v1)\b/i.test(definition) ||
    definition.includes(PRODUCTION_PROJECT_REF)
  );
}

export function fingerprintRows(rows) {
  if (!Array.isArray(rows)) throw new Error('Schema fingerprint failed (INVALID_ROWS)');
  return rows
    .filter((row) => !isAllowedPlatformRow(row))
    .map((row) => {
      if (typeof row?.kind !== 'string' || typeof row?.identity !== 'string') {
        throw new Error('Schema fingerprint failed (INVALID_ROW)');
      }
      return {
        kind: row.kind,
        identity: row.identity,
        hash: hash(normalizeDefinition(row.definition, row.kind)),
      };
    })
    .sort((left, right) =>
      `${left.kind}:${left.identity}`.localeCompare(`${right.kind}:${right.identity}`),
    );
}

export function compareFingerprints(expected, actual) {
  const expectedMap = new Map(expected.map((row) => [`${row.kind}:${row.identity}`, row.hash]));
  const actualMap = new Map(actual.map((row) => [`${row.kind}:${row.identity}`, row.hash]));
  const missing = [...expectedMap.keys()].filter((key) => !actualMap.has(key)).sort();
  const unexpected = [...actualMap.keys()].filter((key) => !expectedMap.has(key)).sort();
  const changed = [...expectedMap.keys()]
    .filter((key) => actualMap.has(key) && actualMap.get(key) !== expectedMap.get(key))
    .sort();
  return { missing, unexpected, changed };
}

export async function fetchProductionRows({ token, fetchImpl = fetch }) {
  assertReadonlyTarget({
    projectRef: PRODUCTION_PROJECT_REF,
    method: 'POST',
    endpoint: ENDPOINT,
    token,
  });
  const response = await fetchImpl(`https://api.supabase.com${ENDPOINT}`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ query: CATALOG_QUERY, parameters: [] }),
  });
  if (!response.ok) {
    throw new Error(redactError(null, { rule: 'FINGERPRINT_HTTP', status: response.status }));
  }
  const result = await response.json();
  if (!Array.isArray(result) || !Array.isArray(result[0]?.rows)) {
    throw new Error('Schema fingerprint failed (INVALID_API_RESPONSE)');
  }
  return result[0].rows;
}

export async function fetchLocalRows({
  databaseUrl = 'postgresql://postgres:postgres@127.0.0.1:54322/postgres',
} = {}) {
  const { stdout } = await execFileAsync('psql', [databaseUrl, '-X', '-A', '-t', '-c', CATALOG_QUERY], {
    maxBuffer: 64 * 1024 * 1024,
  });
  const rows = JSON.parse(stdout.trim());
  if (!Array.isArray(rows)) throw new Error('Schema fingerprint failed (INVALID_LOCAL_RESPONSE)');
  return rows;
}

export async function compareProductionToLocal({ token }) {
  const [productionRows, localRows] = await Promise.all([
    fetchProductionRows({ token }),
    fetchLocalRows(),
  ]);
  const production = fingerprintRows(productionRows);
  const local = fingerprintRows(localRows);
  return {
    productionCount: production.length,
    localCount: local.length,
    diff: compareFingerprints(production, local),
  };
}
