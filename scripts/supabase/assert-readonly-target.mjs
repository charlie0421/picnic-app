export const PRODUCTION_PROJECT_REF = 'xtijtefcycoeqludlngc';

const allowedTargets = new Set([
  `POST /v1/projects/${PRODUCTION_PROJECT_REF}/database/query/read-only`,
  `GET /v1/projects/${PRODUCTION_PROJECT_REF}/analytics/endpoints/logs`,
]);

export function assertReadonlyTarget({ projectRef, method, endpoint, token }) {
  if (projectRef !== PRODUCTION_PROJECT_REF) {
    throw new Error('NO-GO: unsafe Supabase production target (PROJECT_REF)');
  }
  if (typeof token !== 'string' || token.length === 0) {
    throw new Error('NO-GO: unsafe Supabase production target (ACCESS_TOKEN)');
  }
  const target = `${String(method).toUpperCase()} ${endpoint}`;
  if (!allowedTargets.has(target)) {
    throw new Error('NO-GO: unsafe Supabase production target (ENDPOINT)');
  }
}

export function redactError(_error, { rule, status }) {
  const safeRule = /^[A-Z0-9_]+$/.test(rule) ? rule : 'UNKNOWN';
  const safeStatus = Number.isInteger(status) ? status : 'unknown';
  return `Supabase read failed (${safeRule}, status=${safeStatus})`;
}
