import { createHash } from 'node:crypto';

const PRODUCTION_REF = 'xtijtefcycoeqludlngc';

const exclusionRules = [
  {
    id: 'BRANCH_WEBHOOK',
    matches: (sql) =>
      new RegExp(PRODUCTION_REF, 'i').test(sql) &&
      /\b(?:http_post|http_request|functions\/v1|Authorization)\b/i.test(sql),
  },
  {
    id: 'BRANCH_AUTHORIZATION',
    matches: (sql) =>
      /\bBearer\s/i.test(sql) && /\b(?:http_post|http_request|functions\/v1|net\.)\b/i.test(sql),
  },
  {
    id: 'PLATFORM_DEPENDENCY',
    matches: (sql) =>
      /\bsupabase_functions\b/i.test(sql) ||
      /^\s*(?:CREATE|ALTER|DROP)\s+SCHEMA\s+"?(?:auth|storage|realtime|extensions|vault|net|cron)"?\b/i.test(
        sql,
      ) ||
      /^\s*(?:CREATE(?:\s+OR\s+REPLACE)?|ALTER|DROP)\s+(?:TABLE|FUNCTION|VIEW|TYPE|POLICY|TRIGGER)\s+(?:IF\s+(?:NOT\s+)?EXISTS\s+)?"?(?:auth|storage|realtime|extensions|vault|net|cron)"?\./i.test(
        sql,
      ),
  },
  {
    id: 'UNSUPPORTED_POSTGRES_SETTING',
    matches: (sql) => /^\s*SET\s+transaction_timeout\s*=/i.test(sql),
  },
  {
    id: 'DUMP_METADATA',
    matches: (sql) =>
      /\bOWNER\s+TO\b/i.test(sql) ||
      /^\s*(?:GRANT|REVOKE)\b/i.test(sql) ||
      /pg_catalog\.set_config\s*\(\s*'search_path'/i.test(sql) ||
      /\bTABLESPACE\b/i.test(sql),
  },
  {
    id: 'DATA_STATEMENT',
    matches: (sql) => /^\s*(?:INSERT\s+INTO|COPY\b|SELECT\s+pg_catalog\.setval\b)/i.test(sql),
  },
];

const rejectionRules = [
  { id: 'PRODUCTION_ENDPOINT', pattern: new RegExp(PRODUCTION_REF, 'i') },
  { id: 'SECRET_BEARER', pattern: /\bBearer\s+[A-Za-z0-9._~+/-]+/i },
  { id: 'SECRET_KEY', pattern: /\bsb_secret_[A-Za-z0-9_-]+/i },
  {
    id: 'SECRET_JWT',
    pattern: /\beyJ[A-Za-z0-9_-]{5,}\.eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{6,}\b/,
  },
];

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function normalize(sql) {
  return sql
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .filter((line) => !/^\s*--/.test(line))
    .join('\n')
    .replace(/[ \t]+$/gm, '')
    .trim()
    .replace(/;+$/, '');
}

export function splitSqlStatements(sql) {
  const statements = [];
  let buffer = '';
  let index = 0;
  let state = 'normal';
  let dollarTag = '';

  while (index < sql.length) {
    const char = sql[index];
    const next = sql[index + 1];

    if (state === 'single') {
      buffer += char;
      if (char === "'" && next === "'") {
        buffer += next;
        index += 2;
        continue;
      }
      if (char === "'") state = 'normal';
      index += 1;
      continue;
    }

    if (state === 'double') {
      buffer += char;
      if (char === '"' && next === '"') {
        buffer += next;
        index += 2;
        continue;
      }
      if (char === '"') state = 'normal';
      index += 1;
      continue;
    }

    if (state === 'line-comment') {
      buffer += char;
      if (char === '\n') state = 'normal';
      index += 1;
      continue;
    }

    if (state === 'block-comment') {
      buffer += char;
      if (char === '*' && next === '/') {
        buffer += next;
        index += 2;
        state = 'normal';
        continue;
      }
      index += 1;
      continue;
    }

    if (state === 'dollar') {
      if (sql.startsWith(dollarTag, index)) {
        buffer += dollarTag;
        index += dollarTag.length;
        state = 'normal';
        continue;
      }
      buffer += char;
      index += 1;
      continue;
    }

    if (char === "'") {
      state = 'single';
      buffer += char;
      index += 1;
      continue;
    }
    if (char === '"') {
      state = 'double';
      buffer += char;
      index += 1;
      continue;
    }
    if (char === '-' && next === '-') {
      state = 'line-comment';
      buffer += '--';
      index += 2;
      continue;
    }
    if (char === '/' && next === '*') {
      state = 'block-comment';
      buffer += '/*';
      index += 2;
      continue;
    }
    if (char === '$') {
      const match = sql.slice(index).match(/^\$[A-Za-z_][A-Za-z0-9_]*\$|^\$\$/);
      if (match) {
        dollarTag = match[0];
        state = 'dollar';
        buffer += dollarTag;
        index += dollarTag.length;
        continue;
      }
    }
    if (char === ';') {
      if (buffer.trim()) statements.push(buffer.trim());
      buffer = '';
      index += 1;
      continue;
    }

    buffer += char;
    index += 1;
  }

  if (buffer.trim()) statements.push(buffer.trim());
  return statements;
}

export function sanitizeBaseline(history) {
  if (!Array.isArray(history) || history.length === 0) {
    throw new Error('Baseline rejected (EMPTY_HISTORY)');
  }

  const included = [];
  const excludedFunctions = new Set();
  const excludedByRule = {};
  let sourceStatementCount = 0;

  for (const record of history) {
    if (
      typeof record?.version !== 'string' ||
      typeof record?.name !== 'string' ||
      !Array.isArray(record?.statements) ||
      record.statements.some((statement) => typeof statement !== 'string')
    ) {
      throw new Error('Baseline rejected (INVALID_HISTORY)');
    }

    for (const rawStatement of record.statements) {
      sourceStatementCount += 1;
      for (const fragment of splitSqlStatements(rawStatement)) {
        const statement = normalize(fragment);
        if (statement.length === 0) continue;

        const dependentFunction = [...excludedFunctions].find(
          (name) =>
            /^\s*CREATE\s+(?:OR\s+REPLACE\s+)?TRIGGER\b/i.test(statement) &&
            statement.includes(name),
        );
        if (dependentFunction) {
          excludedByRule.DEPENDENT_TRIGGER = (excludedByRule.DEPENDENT_TRIGGER ?? 0) + 1;
          continue;
        }

        const exclusion = exclusionRules.find((rule) => rule.matches(statement));
        if (exclusion) {
          if (/^(?:BRANCH_|PLATFORM_)/.test(exclusion.id)) {
            const functionName = statement.match(
              /^\s*CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+([^\s(]+)/i,
            )?.[1];
            if (functionName) excludedFunctions.add(functionName);
          }
          excludedByRule[exclusion.id] = (excludedByRule[exclusion.id] ?? 0) + 1;
          continue;
        }

        const rejection = rejectionRules.find((rule) => rule.pattern.test(statement));
        if (rejection) {
          throw new Error(`Baseline rejected (${rejection.id})`);
        }

        included.push(statement);
      }
    }
  }

  const body = included.map((statement) => `${statement};`).join('\n\n');
  const sql = [
    '-- Generated by scripts/supabase/export-migration-history.mjs.',
    '-- Contains schema only; production data, endpoints, and credentials are excluded.',
    'SET search_path TO public, extensions;',
    '',
    body,
    '',
  ].join('\n');

  return {
    sql,
    manifest: {
      sourceMigrationCount: history.length,
      sourceStatementCount,
      includedCount: included.length,
      excludedByRule: Object.fromEntries(
        Object.entries(excludedByRule).sort(([left], [right]) => left.localeCompare(right)),
      ),
      sqlSha256: sha256(sql),
    },
  };
}
