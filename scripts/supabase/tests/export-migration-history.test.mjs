import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  BASELINE_VERSION,
  fetchMigrationHistory,
  generateBaseline,
} from '../export-migration-history.mjs';

function response(body, { ok = true, status = 201 } = {}) {
  return { ok, status, json: async () => body };
}

test('fetches schema-qualified migration history through the exact read-only endpoint', async () => {
  const calls = [];
  const records = [
    { version: '20240101', name: 'legacy', statements: ['SELECT 1'] },
    { version: BASELINE_VERSION, name: 'baseline_squash', statements: ['CREATE TABLE public.a(id int)'] },
    { version: '20260501', name: 'later', statements: ['CREATE INDEX a_id_idx ON public.a(id)'] },
  ];
  const result = await fetchMigrationHistory({
    token: 'sentinel-token',
    fetchImpl: async (...args) => {
      calls.push(args);
      return response(records);
    },
  });

  assert.deepEqual(result, records.slice(1));
  assert.equal(calls.length, 1);
  const [url, options] = calls[0];
  assert.equal(
    url,
    'https://api.supabase.com/v1/projects/xtijtefcycoeqludlngc/database/query/read-only',
  );
  assert.equal(options.method, 'POST');
  assert.equal(options.headers.authorization, 'Bearer sentinel-token');
  const request = JSON.parse(options.body);
  assert.match(request.query, /supabase_migrations\.schema_migrations/);
  assert.match(request.query, /order by version/);
});

test('rejects missing or duplicate baseline records and malformed API rows', async () => {
  for (const body of [
    [],
    [
      { version: BASELINE_VERSION, name: 'baseline_squash', statements: [] },
      { version: BASELINE_VERSION, name: 'baseline_squash', statements: [] },
    ],
    [{ version: BASELINE_VERSION, name: 'baseline_squash', statements: 'bad' }],
  ]) {
    await assert.rejects(
      fetchMigrationHistory({ token: 'sentinel-token', fetchImpl: async () => response(body) }),
      /BASELINE_|INVALID_API_RESPONSE/,
    );
  }
});

test('redacts HTTP failures', async () => {
  await assert.rejects(
    fetchMigrationHistory({
      token: 'sentinel-token',
      fetchImpl: async () => response({ secret: 'sentinel-token' }, { ok: false, status: 403 }),
    }),
    (error) => {
      assert.match(error.message, /HTTP_FAILURE/);
      assert.equal(error.message.includes('sentinel-token'), false);
      return true;
    },
  );
});

test('atomically writes only sanitized output and preserves prior output on rejection', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'clean-baseline-test-'));
  const outputPath = join(directory, 'baseline.sql');
  await writeFile(outputPath, 'previous-content', 'utf8');

  try {
    const manifest = await generateBaseline({
      outputPath,
      token: 'sentinel-token',
      fetchImpl: async () =>
        response([
          {
            version: BASELINE_VERSION,
            name: 'baseline_squash',
            statements: ['CREATE TABLE public.a(id int)'],
          },
        ]),
    });
    assert.equal(manifest.includedCount, 1);
    assert.match(await readFile(outputPath, 'utf8'), /CREATE TABLE public\.a/);

    await assert.rejects(
      generateBaseline({
        outputPath,
        token: 'sentinel-token',
        fetchImpl: async () =>
          response([
            {
              version: BASELINE_VERSION,
              name: 'baseline_squash',
              statements: ["SELECT 'service_role'"],
            },
          ]),
      }),
      /SECRET_SERVICE_ROLE/,
    );
    assert.match(await readFile(outputPath, 'utf8'), /CREATE TABLE public\.a/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
