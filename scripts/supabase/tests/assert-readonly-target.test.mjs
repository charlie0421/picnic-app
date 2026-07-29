import assert from 'node:assert/strict';
import test from 'node:test';

import {
  PRODUCTION_PROJECT_REF,
  assertReadonlyTarget,
  redactError,
} from '../assert-readonly-target.mjs';

test('allows only the production read-only database endpoint', () => {
  assert.doesNotThrow(() =>
    assertReadonlyTarget({
      projectRef: PRODUCTION_PROJECT_REF,
      method: 'POST',
      endpoint: `/v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`,
      token: 'sentinel-token',
    }),
  );
});

test('allows production log reads', () => {
  assert.doesNotThrow(() =>
    assertReadonlyTarget({
      projectRef: PRODUCTION_PROJECT_REF,
      method: 'GET',
      endpoint: `/v1/projects/${PRODUCTION_PROJECT_REF}/analytics/endpoints/logs`,
      token: 'sentinel-token',
    }),
  );
});

for (const unsafe of [
  { method: 'POST', endpoint: `/v1/projects/xtijtefcycoeqludlngc/database/query` },
  { method: 'PATCH', endpoint: `/v1/projects/xtijtefcycoeqludlngc/database/migrations/1` },
  { method: 'POST', endpoint: `/v1/projects/xtijtefcycoeqludlngc/branches` },
  { method: 'DELETE', endpoint: `/v1/projects/xtijtefcycoeqludlngc/branches` },
]) {
  test(`rejects unsafe target ${unsafe.method} ${unsafe.endpoint}`, () => {
    assert.throws(
      () =>
        assertReadonlyTarget({
          projectRef: PRODUCTION_PROJECT_REF,
          token: 'sentinel-token',
          ...unsafe,
        }),
      /NO-GO: unsafe Supabase production target/,
    );
  });
}

test('rejects unknown project refs and missing tokens', () => {
  assert.throws(
    () =>
      assertReadonlyTarget({
        projectRef: 'unknown-project',
        method: 'POST',
        endpoint: '/v1/projects/unknown-project/database/query/read-only',
        token: 'sentinel-token',
      }),
    /PROJECT_REF/,
  );
  assert.throws(
    () =>
      assertReadonlyTarget({
        projectRef: PRODUCTION_PROJECT_REF,
        method: 'POST',
        endpoint: `/v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`,
        token: '',
      }),
    /ACCESS_TOKEN/,
  );
});

test('redacts secret values from errors', () => {
  const secret = 'sentinel-super-secret-token';
  const result = redactError(new Error(`request failed with ${secret}`), {
    rule: 'HTTP_FAILURE',
    status: 403,
  });
  assert.equal(result, 'Supabase read failed (HTTP_FAILURE, status=403)');
  assert.equal(result.includes(secret), false);
});
