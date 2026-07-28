import assert from 'node:assert/strict';
import test from 'node:test';

import {
  compareFingerprints,
  fingerprintRows,
  isAllowedPlatformRow,
} from '../schema-fingerprint.mjs';

test('fingerprints catalog rows deterministically without definitions', () => {
  const rows = [
    { kind: 'column', identity: 'public.b.id', definition: ' bigint   not null ' },
    { kind: 'table', identity: 'public.b', definition: 'rls=true' },
  ];
  const first = fingerprintRows(rows);
  const second = fingerprintRows([...rows].reverse());
  assert.deepEqual(first, second);
  assert.deepEqual(first.map(({ kind, identity }) => ({ kind, identity })), [
    { kind: 'column', identity: 'public.b.id' },
    { kind: 'table', identity: 'public.b' },
  ]);
  assert.equal(JSON.stringify(first).includes('bigint'), false);
  assert.match(first[0].hash, /^[a-f0-9]{64}$/);
});

test('normalizes harmless schema qualification, quoting, and comments', () => {
  const qualified = fingerprintRows([
    {
      kind: 'column',
      identity: 'public.t.id',
      definition: '-- dump comment\nextensions.uuid_generate_v4()',
    },
  ]);
  const unqualified = fingerprintRows([
    { kind: 'column', identity: 'public.t.id', definition: '"uuid_generate_v4"()' },
  ]);
  assert.deepEqual(qualified, unqualified);

  const explicitCasts = fingerprintRows([
    {
      kind: 'constraint',
      identity: 'public.t.status_check',
      definition: "CHECK (status::text = ANY (ARRAY['open'::character varying]::text[]))",
    },
  ]);
  const implicitCasts = fingerprintRows([
    {
      kind: 'constraint',
      identity: 'public.t.status_check',
      definition: "CHECK (status = ANY (ARRAY['open']))",
    },
  ]);
  assert.deepEqual(explicitCasts, implicitCasts);

  const arrayCastLayout = fingerprintRows([
    {
      kind: 'policy',
      identity: 'public.t.admin',
      definition: "name = ANY ((ARRAY['super_admin'::character varying, 'admin'::character varying])::text[])",
    },
  ]);
  const elementCastLayout = fingerprintRows([
    {
      kind: 'policy',
      identity: 'public.t.admin',
      definition: "name = ANY (ARRAY[('super_admin'::character varying)::text, ('admin'::character varying)::text])",
    },
  ]);
  assert.deepEqual(arrayCastLayout, elementCastLayout);
});

test('filters platform and branch-specific webhook rows', () => {
  assert.equal(
    isAllowedPlatformRow({
      kind: 'function',
      identity: 'public.notify_alarm()',
      definition: "select net.http_post(url := 'https://xtijtefcycoeqludlngc.supabase.co')",
    }),
    true,
  );
  assert.equal(
    isAllowedPlatformRow({
      kind: 'function',
      identity: 'public.similarity(text,text)',
      definition: 'extension=pg_trgm|CREATE FUNCTION public.similarity(text,text)',
    }),
    true,
  );
  assert.equal(
    isAllowedPlatformRow({
      kind: 'table',
      identity: 'public.cs_4_11_classification',
      definition: 'rls=false',
    }),
    true,
  );
  assert.equal(
    isAllowedPlatformRow({
      kind: 'trigger',
      identity: 'public.qna_messages.alarm-qna-message',
      definition: 'execute function public.notify_qna_alarm()',
    }),
    true,
  );
  assert.equal(
    isAllowedPlatformRow({
      kind: 'trigger',
      identity: 'public.t.alarm',
      definition: 'execute function supabase_functions.http_request()',
    }),
    true,
  );
  assert.equal(
    isAllowedPlatformRow({ kind: 'table', identity: 'public.users', definition: 'rls=true' }),
    false,
  );
});

test('reports missing, unexpected, and changed application objects', () => {
  const expected = fingerprintRows([
    { kind: 'table', identity: 'public.a', definition: 'rls=true' },
    { kind: 'table', identity: 'public.b', definition: 'rls=false' },
  ]);
  const actual = fingerprintRows([
    { kind: 'table', identity: 'public.a', definition: 'rls=false' },
    { kind: 'table', identity: 'public.c', definition: 'rls=false' },
  ]);
  assert.deepEqual(compareFingerprints(expected, actual), {
    missing: ['table:public.b'],
    unexpected: ['table:public.c'],
    changed: ['table:public.a'],
  });
});
