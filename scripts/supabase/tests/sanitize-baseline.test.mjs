import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { sanitizeBaseline, splitSqlStatements } from '../sanitize-baseline.mjs';

const fixtures = new URL('./fixtures/', import.meta.url);

async function fixture(name) {
  return JSON.parse(await readFile(new URL(name, fixtures), 'utf8'));
}

test('sanitizes a baseline deterministically', async () => {
  const history = await fixture('migration-statements-safe.json');
  const first = sanitizeBaseline(history);
  const second = sanitizeBaseline(history);

  assert.deepEqual(first, second);
  assert.match(first.sql, /CREATE TABLE public\.example/);
  assert.match(first.sql, /CREATE INDEX example_id_idx/);
  assert.doesNotMatch(first.sql, /transaction_timeout/);
  assert.doesNotMatch(first.sql, /supabase_functions/);
  assert.doesNotMatch(first.sql, /Bearer/);
  assert.doesNotMatch(first.sql, /OWNER TO/);
  assert.doesNotMatch(first.sql, /INSERT INTO/);
  assert.equal(first.manifest.includedCount, 3);
  assert.deepEqual(first.manifest.excludedByRule, {
    DATA_STATEMENT: 1,
    DUMP_METADATA: 2,
    BRANCH_AUTHORIZATION: 1,
    UNSUPPORTED_POSTGRES_SETTING: 1,
  });
  assert.match(first.manifest.sqlSha256, /^[a-f0-9]{64}$/);
  assert.match(first.sql, /SET search_path TO public, extensions/);
});

test('rejects secrets outside an excluded platform statement without echoing them', async () => {
  const history = await fixture('migration-statements-rejected.json');
  let error;
  try {
    sanitizeBaseline(history);
  } catch (caught) {
    error = caught;
  }
  assert.ok(error);
  assert.match(error.message, /SECRET_JWT/);
  assert.equal(error.message.includes('eyJfake0.eyJfake1.signature'), false);
});

test('rejects production endpoints and authorization material', () => {
  for (const statement of [
    "SELECT 'https://xtijtefcycoeqludlngc.supabase.co'",
    "SELECT 'Bearer abcdef'",
    "SELECT 'sb_secret_example'",
  ]) {
    assert.throws(
      () =>
        sanitizeBaseline([
          { version: '20260425161337', name: 'baseline_squash', statements: [statement] },
        ]),
      /SECRET_|PRODUCTION_ENDPOINT/,
    );
  }
});

test('allows service_role as a database role identifier', () => {
  const result = sanitizeBaseline([
    {
      version: '20260425161337',
      name: 'baseline_squash',
      statements: [
        'CREATE POLICY server_only ON public.safe_table TO service_role USING (true)',
      ],
    },
  ]);
  assert.match(result.sql, /TO service_role/);
});

test('keeps application policies that call auth.uid()', () => {
  const result = sanitizeBaseline([
    {
      version: '20260425161337',
      name: 'baseline_squash',
      statements: [
        'CREATE POLICY own_rows ON public.safe_table FOR SELECT TO authenticated USING (auth.uid() = user_id)',
      ],
    },
  ]);
  assert.match(result.sql, /CREATE POLICY own_rows/);
  assert.match(result.sql, /auth\.uid\(\)/);
});

test('excludes branch-specific webhook statements before inspecting embedded credentials', () => {
  const result = sanitizeBaseline([
    {
      version: '20260425161337',
      name: 'baseline_squash',
      statements: [
        "CREATE FUNCTION public.notify() RETURNS void LANGUAGE sql AS $$ SELECT net.http_post(url := 'https://xtijtefcycoeqludlngc.supabase.co/functions/v1/notify', headers := '{\"Authorization\":\"Bearer eyJfake0.eyJfake1.signature\"}') $$",
        'CREATE TABLE public.safe_table(id int)',
      ],
    },
  ]);
  assert.doesNotMatch(result.sql, /notify|xtijtefcycoeqludlngc|Bearer/);
  assert.equal(result.manifest.excludedByRule.BRANCH_WEBHOOK, 1);
});

test('removes dump comments before production endpoint inspection', () => {
  const result = sanitizeBaseline([
    {
      version: '20260425161337',
      name: 'baseline_squash',
      statements: [
        '-- source project: xtijtefcycoeqludlngc\nCREATE TABLE public.comment_safe(id int)',
      ],
    },
  ]);
  assert.match(result.sql, /CREATE TABLE public\.comment_safe/);
  assert.doesNotMatch(result.sql, /xtijtefcycoeqludlngc|source project/);
});

test('rejects malformed history conservatively', () => {
  assert.throws(() => sanitizeBaseline([]), /EMPTY_HISTORY/);
  assert.throws(
    () => sanitizeBaseline([{ version: '1', name: 'bad', statements: 'not-array' }]),
    /INVALID_HISTORY/,
  );
});

test('splits top-level SQL without splitting quoted or function-body semicolons', () => {
  const sql = `
    CREATE TABLE public.a(value text DEFAULT ';');
    CREATE FUNCTION public.f() RETURNS void LANGUAGE plpgsql AS $body$
    BEGIN
      PERFORM 1;
    END;
    $body$;
    CREATE TABLE public.b(id int);
  `;
  const statements = splitSqlStatements(sql);
  assert.equal(statements.length, 3);
  assert.match(statements[1], /PERFORM 1;/);
});

test('removes only webhook fragments from a bundled migration', () => {
  const result = sanitizeBaseline([
    {
      version: '20260722072719',
      name: 'bundled_change',
      statements: [
        "ALTER TABLE public.safe_table ADD COLUMN note text; CREATE TRIGGER webhook AFTER INSERT ON public.safe_table FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://branch.invalid', 'POST', '{\"Authorization\":\"Bearer value\"}', '{}', '1000'); CREATE INDEX safe_note_idx ON public.safe_table(note);",
      ],
    },
  ]);
  assert.match(result.sql, /ADD COLUMN note/);
  assert.match(result.sql, /CREATE INDEX safe_note_idx/);
  assert.doesNotMatch(result.sql, /supabase_functions|Bearer/);
});

test('removes triggers that depend on an excluded webhook function', () => {
  const result = sanitizeBaseline([
    {
      version: '20260722072719',
      name: 'vault_webhook',
      statements: [
        "CREATE FUNCTION public.notify_alarm() RETURNS void LANGUAGE sql AS $$ SELECT net.http_post(url := 'https://branch.invalid', headers := '{\"Authorization\":\"Bearer value\"}') $$; CREATE TRIGGER alarm AFTER INSERT ON public.safe_table FOR EACH ROW EXECUTE FUNCTION public.notify_alarm(); CREATE TRIGGER keep_me AFTER INSERT ON public.safe_table FOR EACH ROW EXECUTE FUNCTION public.safe_trigger();",
      ],
    },
  ]);
  assert.doesNotMatch(result.sql, /notify_alarm|CREATE TRIGGER alarm/);
  assert.match(result.sql, /CREATE TRIGGER keep_me/);
  assert.equal(result.manifest.excludedByRule.DEPENDENT_TRIGGER, 1);
});
