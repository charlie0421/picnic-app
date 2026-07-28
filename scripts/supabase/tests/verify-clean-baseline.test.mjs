import assert from 'node:assert/strict';
import test from 'node:test';

import { runRemoteVerification } from '../verify-clean-baseline.mjs';

test('creates a data-less ephemeral git branch and always deletes it', async () => {
  const calls = [];
  const client = {
    create: async (input) => {
      calls.push(['create', input]);
      return { project_ref: 'abcdefghijklmnopqrst' };
    },
    status: async () => ({ status: 'FUNCTIONS_DEPLOYED', preview_project_status: 'ACTIVE_HEALTHY' }),
    apiStatus: async () => 401,
    compareFingerprint: async () => ({ missing: [], unexpected: [], changed: [] }),
    remove: async (ref) => calls.push(['remove', ref]),
    exists: async () => false,
  };

  const result = await runRemoteVerification({
    client,
    branchName: 'verify-clean-baseline-test',
    gitBranch: 'fix/supabase-clean-baseline',
    wait: async () => {},
  });

  assert.equal(result.status, 'FUNCTIONS_DEPLOYED');
  assert.deepEqual(calls[0], [
    'create',
    {
      branchName: 'verify-clean-baseline-test',
      gitBranch: 'fix/supabase-clean-baseline',
      persistent: false,
      withData: false,
    },
  ]);
  assert.deepEqual(calls.at(-1), ['remove', 'abcdefghijklmnopqrst']);
});

test('deletes the branch when migrations fail', async () => {
  let removed = false;
  const client = {
    create: async () => ({ project_ref: 'abcdefghijklmnopqrst' }),
    status: async () => ({ status: 'MIGRATIONS_FAILED', preview_project_status: 'ACTIVE_HEALTHY' }),
    remove: async () => {
      removed = true;
    },
    exists: async () => false,
  };
  await assert.rejects(
    runRemoteVerification({
      client,
      branchName: 'verify-clean-baseline-test',
      gitBranch: 'fix/supabase-clean-baseline',
      wait: async () => {},
    }),
    /REMOTE_MIGRATIONS_FAILED/,
  );
  assert.equal(removed, true);
});

test('rejects unsafe branch inputs before mutation', async () => {
  const client = { create: async () => assert.fail('must not create') };
  await assert.rejects(
    runRemoteVerification({
      client,
      branchName: 'development',
      gitBranch: 'main',
      wait: async () => {},
    }),
    /UNSAFE_BRANCH_INPUT/,
  );
});
