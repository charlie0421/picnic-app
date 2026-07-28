import assert from 'node:assert/strict';
import test from 'node:test';

import { buildSchemaOverlay } from '../schema-overlay.mjs';

test('builds safe index, constraint, and policy overlay SQL', () => {
  const productionRows = [
    {
      kind: 'index',
      identity: 'public.items.items_name_idx',
      definition: 'CREATE INDEX items_name_idx ON public.items USING btree (name)',
    },
    {
      kind: 'constraint',
      identity: 'public.items.items_status_check',
      definition: "CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text])))",
    },
    {
      kind: 'policy',
      identity: 'public.items.own_items',
      definition: 'fingerprint-only',
    },
  ];
  const localRows = [
    {
      kind: 'constraint',
      identity: 'public.items.items_status_check',
      definition: "CHECK ((status = 'open'::text))",
    },
    { kind: 'policy', identity: 'public.items.own_items', definition: 'old' },
  ];
  const policies = [
    {
      schemaname: 'public',
      tablename: 'items',
      policyname: 'own_items',
      permissive: 'PERMISSIVE',
      roles: ['authenticated'],
      cmd: 'SELECT',
      qual: '(auth.uid() = user_id)',
      with_check: null,
    },
  ];

  const overlay = buildSchemaOverlay({ productionRows, localRows, policies });
  assert.match(overlay.sql, /CREATE INDEX IF NOT EXISTS items_name_idx/);
  assert.match(overlay.sql, /DROP CONSTRAINT IF EXISTS "items_status_check"/);
  assert.match(overlay.sql, /ADD CONSTRAINT "items_status_check" CHECK/);
  assert.match(overlay.sql, /DROP POLICY IF EXISTS "own_items"/);
  assert.match(overlay.sql, /TO "authenticated"/);
  assert.match(overlay.sql, /USING \(\(auth\.uid\(\) = user_id\)\)/);
  assert.deepEqual(overlay.counts, { indexes: 1, constraints: 1, policies: 1 });
});

test('rejects unsupported schema drift', () => {
  assert.throws(
    () =>
      buildSchemaOverlay({
        productionRows: [{ kind: 'table', identity: 'public.missing', definition: 'rls=false' }],
        localRows: [],
        policies: [],
      }),
    /UNSUPPORTED_DRIFT/,
  );
});
