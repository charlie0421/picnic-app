import { fileURLToPath } from 'node:url';

import { PRODUCTION_PROJECT_REF } from './assert-readonly-target.mjs';
import {
  CATALOG_QUERY,
  compareFingerprints,
  fetchProductionRows,
  fingerprintRows,
} from './schema-fingerprint.mjs';

const API_ORIGIN = 'https://api.supabase.com';

function assertBranchInputs({ branchName, gitBranch }) {
  if (
    !/^verify-clean-baseline-[a-z0-9-]+$/.test(branchName) ||
    gitBranch !== 'fix/supabase-clean-baseline'
  ) {
    throw new Error('Remote verification failed (UNSAFE_BRANCH_INPUT)');
  }
}

export async function runRemoteVerification({
  client,
  branchName,
  gitBranch,
  wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)),
  maxPolls = 60,
}) {
  assertBranchInputs({ branchName, gitBranch });
  let branchRef;
  try {
    const branch = await client.create({
      branchName,
      gitBranch,
      persistent: false,
      withData: false,
    });
    branchRef = branch.project_ref;
    if (!/^[a-z]{20}$/.test(branchRef)) {
      throw new Error('Remote verification failed (INVALID_BRANCH_REF)');
    }

    let current;
    for (let attempt = 0; attempt < maxPolls; attempt += 1) {
      current = await client.status(branchRef);
      if (current.status === 'MIGRATIONS_FAILED') {
        throw new Error('Remote verification failed (REMOTE_MIGRATIONS_FAILED)');
      }
      if (
        current.status === 'FUNCTIONS_DEPLOYED' &&
        current.preview_project_status === 'ACTIVE_HEALTHY'
      ) {
        break;
      }
      if (attempt === maxPolls - 1) {
        throw new Error('Remote verification failed (STATUS_TIMEOUT)');
      }
      await wait(5000);
    }

    if ((await client.apiStatus(branchRef)) !== 401) {
      throw new Error('Remote verification failed (API_STATUS)');
    }
    const diff = await client.compareFingerprint(branchRef);
    if (diff.missing.length || diff.unexpected.length || diff.changed.length) {
      throw new Error('Remote verification failed (SCHEMA_MISMATCH)');
    }
    return { status: current.status, projectStatus: current.preview_project_status };
  } finally {
    if (branchRef) {
      await client.remove(branchRef);
      if (await client.exists(branchRef)) {
        throw new Error('Remote verification failed (CLEANUP_FAILED)');
      }
    }
  }
}

export function createManagementClient({ token, fetchImpl = fetch }) {
  const request = async (path, options = {}) => {
    const response = await fetchImpl(`${API_ORIGIN}${path}`, {
      ...options,
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
        ...(options.headers ?? {}),
      },
    });
    if (!response.ok) {
      throw new Error(`Remote verification failed (MANAGEMENT_HTTP_${response.status})`);
    }
    if (response.status === 204) return null;
    return response.json();
  };

  const list = () => request(`/v1/projects/${PRODUCTION_PROJECT_REF}/branches`);
  const fetchBranchRows = async (branchRef) => {
    if (!/^[a-z]{20}$/.test(branchRef) || branchRef === PRODUCTION_PROJECT_REF) {
      throw new Error('Remote verification failed (INVALID_BRANCH_REF)');
    }
    const result = await request(`/v1/projects/${branchRef}/database/query/read-only`, {
      method: 'POST',
      body: JSON.stringify({ query: CATALOG_QUERY, parameters: [] }),
    });
    if (!Array.isArray(result) || !Array.isArray(result[0]?.rows)) {
      throw new Error('Remote verification failed (INVALID_FINGERPRINT_RESPONSE)');
    }
    return result[0].rows;
  };

  return {
    create: ({ branchName, gitBranch, persistent, withData }) =>
      request(`/v1/projects/${PRODUCTION_PROJECT_REF}/branches`, {
        method: 'POST',
        body: JSON.stringify({
          branch_name: branchName,
          git_branch: gitBranch,
          persistent,
          with_data: withData,
        }),
      }),
    status: async (branchRef) => {
      const branch = (await list()).find((candidate) => candidate.project_ref === branchRef);
      if (!branch) throw new Error('Remote verification failed (BRANCH_NOT_FOUND)');
      return branch;
    },
    apiStatus: async (branchRef) => {
      const response = await fetchImpl(`https://${branchRef}.supabase.co/rest/v1/`);
      return response.status;
    },
    compareFingerprint: async (branchRef) => {
      const [productionRows, branchRows] = await Promise.all([
        fetchProductionRows({ token, fetchImpl }),
        fetchBranchRows(branchRef),
      ]);
      return compareFingerprints(fingerprintRows(productionRows), fingerprintRows(branchRows));
    },
    remove: (branchRef) => request(`/v1/branches/${branchRef}`, { method: 'DELETE' }),
    exists: async (branchRef) =>
      (await list()).some((candidate) => candidate.project_ref === branchRef),
  };
}

async function main() {
  const token = process.env.SUPABASE_ACCESS_TOKEN ?? '';
  if (!token) throw new Error('Remote verification failed (ACCESS_TOKEN)');
  const suffix = Date.now().toString(36);
  const result = await runRemoteVerification({
    client: createManagementClient({ token }),
    branchName: `verify-clean-baseline-${suffix}`,
    gitBranch: 'fix/supabase-clean-baseline',
  });
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
