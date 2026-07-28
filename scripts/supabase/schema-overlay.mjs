import { readFile, rename, unlink, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

import {
  PRODUCTION_PROJECT_REF,
  assertReadonlyTarget,
  redactError,
} from './assert-readonly-target.mjs';
import {
  compareFingerprints,
  fetchLocalRows,
  fetchProductionRows,
  fingerprintRows,
} from './schema-fingerprint.mjs';

const ENDPOINT = `/v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`;
const OVERLAY_MARKER = '-- CLEAN BASELINE SCHEMA OVERLAY';

const POLICY_QUERY = `
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where schemaname = 'public'
order by tablename, policyname`;

function quoteIdentifier(value) {
  return `"${String(value).replaceAll('"', '""')}"`;
}

function identityParts(identity) {
  const parts = identity.split('.');
  if (parts.length < 3 || parts[0] !== 'public') {
    throw new Error('Schema overlay failed (INVALID_IDENTITY)');
  }
  return { table: parts[1], name: parts.slice(2).join('.') };
}

function indexWithIfNotExists(definition) {
  if (/^CREATE UNIQUE INDEX\b/i.test(definition)) {
    return definition.replace(/^CREATE UNIQUE INDEX\b/i, 'CREATE UNIQUE INDEX IF NOT EXISTS');
  }
  if (/^CREATE INDEX\b/i.test(definition)) {
    return definition.replace(/^CREATE INDEX\b/i, 'CREATE INDEX IF NOT EXISTS');
  }
  throw new Error('Schema overlay failed (INVALID_INDEX_DEFINITION)');
}

function createPolicySql(policy) {
  const roles = policy.roles.map(quoteIdentifier).join(', ');
  const clauses = [
    `CREATE POLICY ${quoteIdentifier(policy.policyname)}`,
    `ON ${quoteIdentifier(policy.schemaname)}.${quoteIdentifier(policy.tablename)}`,
    `AS ${policy.permissive}`,
    `FOR ${policy.cmd}`,
    `TO ${roles}`,
  ];
  if (policy.qual) clauses.push(`USING (${policy.qual})`);
  if (policy.with_check) clauses.push(`WITH CHECK (${policy.with_check})`);
  return clauses.join('\n');
}

export function buildSchemaOverlay({ productionRows, localRows, policies }) {
  const productionFingerprint = fingerprintRows(productionRows);
  const localFingerprint = fingerprintRows(localRows);
  const diff = compareFingerprints(productionFingerprint, localFingerprint);
  const productionByKey = new Map(
    productionRows.map((row) => [`${row.kind}:${row.identity}`, row]),
  );
  const statements = [];
  const counts = { indexes: 0, constraints: 0, policies: 0 };

  for (const key of diff.missing) {
    if (!key.startsWith('index:')) {
      throw new Error(`Schema overlay failed (UNSUPPORTED_DRIFT:${key.split(':', 1)[0]})`);
    }
    const row = productionByKey.get(key);
    statements.push(indexWithIfNotExists(row.definition));
    counts.indexes += 1;
  }

  for (const key of diff.changed) {
    const row = productionByKey.get(key);
    if (key.startsWith('constraint:')) {
      const { table, name } = identityParts(row.identity);
      statements.push(
        `ALTER TABLE ${quoteIdentifier('public')}.${quoteIdentifier(table)} DROP CONSTRAINT IF EXISTS ${quoteIdentifier(name)}`,
        `ALTER TABLE ${quoteIdentifier('public')}.${quoteIdentifier(table)} ADD CONSTRAINT ${quoteIdentifier(name)} ${row.definition}`,
      );
      counts.constraints += 1;
      continue;
    }
    if (key.startsWith('policy:')) {
      const { table, name } = identityParts(row.identity);
      const policy = policies.find(
        (candidate) => candidate.tablename === table && candidate.policyname === name,
      );
      if (!policy) throw new Error('Schema overlay failed (POLICY_MISSING)');
      statements.push(
        `DROP POLICY IF EXISTS ${quoteIdentifier(name)} ON ${quoteIdentifier('public')}.${quoteIdentifier(table)}`,
        createPolicySql(policy),
      );
      counts.policies += 1;
      continue;
    }
    throw new Error(`Schema overlay failed (UNSUPPORTED_DRIFT:${key.split(':', 1)[0]})`);
  }

  if (diff.unexpected.length > 0) {
    throw new Error('Schema overlay failed (UNSUPPORTED_DRIFT:unexpected)');
  }

  return {
    sql: `${[OVERLAY_MARKER, ...statements.map((statement) => `${statement};`)].join('\n\n')}\n`,
    counts,
  };
}

export async function fetchProductionPolicies({ token, fetchImpl = fetch }) {
  assertReadonlyTarget({
    projectRef: PRODUCTION_PROJECT_REF,
    method: 'POST',
    endpoint: ENDPOINT,
    token,
  });
  const response = await fetchImpl(`https://api.supabase.com${ENDPOINT}`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ query: POLICY_QUERY, parameters: [] }),
  });
  if (!response.ok) {
    throw new Error(redactError(null, { rule: 'POLICY_HTTP', status: response.status }));
  }
  const policies = await response.json();
  if (!Array.isArray(policies)) {
    throw new Error('Schema overlay failed (INVALID_POLICY_RESPONSE)');
  }
  return policies.map((policy) => {
    const roles = Array.isArray(policy.roles)
      ? policy.roles
      : typeof policy.roles === 'string' && /^\{[^{}]*\}$/.test(policy.roles)
        ? policy.roles.slice(1, -1).split(',').filter(Boolean)
        : null;
    if (!roles) throw new Error('Schema overlay failed (INVALID_POLICY_RESPONSE)');
    return { ...policy, roles };
  });
}

export async function appendSchemaOverlay({ baselinePath, token }) {
  const [productionRows, localRows, policies, baseline] = await Promise.all([
    fetchProductionRows({ token }),
    fetchLocalRows(),
    fetchProductionPolicies({ token }),
    readFile(baselinePath, 'utf8'),
  ]);
  const { sql, counts } = buildSchemaOverlay({ productionRows, localRows, policies });
  if (baseline.includes(OVERLAY_MARKER) && Object.values(counts).every((count) => count === 0)) {
    return counts;
  }
  const base = baseline.split(OVERLAY_MARKER, 1)[0].trimEnd();
  const output = `${base}\n\n${sql}`;
  const temporaryPath = `${baselinePath}.overlay-${process.pid}`;
  try {
    await writeFile(temporaryPath, output, { encoding: 'utf8', mode: 0o600 });
    await rename(temporaryPath, baselinePath);
  } catch (error) {
    await unlink(temporaryPath).catch(() => {});
    throw error;
  }
  return counts;
}

async function main() {
  const baselinePath = process.argv[2];
  if (!baselinePath) throw new Error('Usage: node schema-overlay.mjs <baseline-path>');
  const counts = await appendSchemaOverlay({
    baselinePath,
    token: process.env.SUPABASE_ACCESS_TOKEN ?? '',
  });
  process.stdout.write(`${JSON.stringify(counts)}\n`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
