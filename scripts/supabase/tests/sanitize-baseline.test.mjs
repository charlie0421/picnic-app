import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { sanitizeBaseline } from '../sanitize-baseline.mjs';

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
    DUMP_METADATA: 1,
    PLATFORM_DEPENDENCY: 1,
    UNSUPPORTED_POSTGRES_SETTING: 1,
  });
  assert.match(first.manifest.sqlSha256, /^[a-f0-9]{64}$/);
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
  assert.equal(error.message.includes('sentinel.header.signature'), false);
});

test('rejects production endpoints and authorization material', () => {
  for (const statement of [
    "SELECT 'https://xtijtefcycoeqludlngc.supabase.co'",
    "SELECT 'Bearer abcdef'",
    "SELECT 'service_role'",
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

test('rejects malformed history conservatively', () => {
  assert.throws(() => sanitizeBaseline([]), /EMPTY_HISTORY/);
  assert.throws(
    () => sanitizeBaseline([{ version: '1', name: 'bad', statements: 'not-array' }]),
    /INVALID_HISTORY/,
  );
});
