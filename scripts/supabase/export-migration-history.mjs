import { rename, unlink, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

import {
  PRODUCTION_PROJECT_REF,
  assertReadonlyTarget,
  redactError,
} from './assert-readonly-target.mjs';
import { sanitizeBaseline } from './sanitize-baseline.mjs';

export const BASELINE_VERSION = '20260425161337';
const API_ORIGIN = 'https://api.supabase.com';
const READ_ONLY_ENDPOINT = `/v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`;

export async function fetchMigrationHistory({ token, fetchImpl = fetch }) {
  assertReadonlyTarget({
    projectRef: PRODUCTION_PROJECT_REF,
    method: 'POST',
    endpoint: READ_ONLY_ENDPOINT,
    token,
  });

  const response = await fetchImpl(`${API_ORIGIN}${READ_ONLY_ENDPOINT}`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      query:
        'select version, name, statements from supabase_migrations.schema_migrations order by version',
      parameters: [],
    }),
  });

  if (!response.ok) {
    throw new Error(redactError(null, { rule: 'HTTP_FAILURE', status: response.status }));
  }

  const history = await response.json();
  if (
    !Array.isArray(history) ||
    history.some(
      (record) =>
        typeof record?.version !== 'string' ||
        typeof record?.name !== 'string' ||
        !Array.isArray(record?.statements) ||
        record.statements.some((statement) => typeof statement !== 'string'),
    )
  ) {
    throw new Error('Baseline export failed (INVALID_API_RESPONSE)');
  }

  const baselineRecords = history.filter(
    (record) => record.version === BASELINE_VERSION && record.name === 'baseline_squash',
  );
  if (baselineRecords.length === 0) {
    throw new Error('Baseline export failed (BASELINE_MISSING)');
  }
  if (baselineRecords.length !== 1) {
    throw new Error('Baseline export failed (BASELINE_DUPLICATE)');
  }

  return history.filter((record) => record.version >= BASELINE_VERSION);
}

export async function generateBaseline({ outputPath, token, fetchImpl = fetch }) {
  const history = await fetchMigrationHistory({ token, fetchImpl });
  const { sql, manifest } = sanitizeBaseline(history);
  const temporaryPath = `${outputPath}.tmp-${process.pid}`;
  try {
    await writeFile(temporaryPath, sql, { encoding: 'utf8', mode: 0o600 });
    await rename(temporaryPath, outputPath);
  } catch (error) {
    await unlink(temporaryPath).catch(() => {});
    throw error;
  }
  return manifest;
}

async function main() {
  const outputPath = process.argv[2];
  if (!outputPath) throw new Error('Usage: node export-migration-history.mjs <output-path>');
  const manifest = await generateBaseline({
    outputPath,
    token: process.env.SUPABASE_ACCESS_TOKEN ?? '',
  });
  process.stdout.write(`${JSON.stringify(manifest)}\n`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
