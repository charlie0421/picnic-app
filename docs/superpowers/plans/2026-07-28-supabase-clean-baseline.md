# Supabase Clean Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Production을 변경하지 않고 현재 migration history를 재생 가능한 PostgreSQL 15 clean baseline으로 변환하고, 로컬과 임시 Supabase branch에서 검증한다.

**Architecture:** Supabase Management API의 read-only query로 production migration statements와 schema fingerprint만 읽는다. 별도 Node.js 도구가 위험 statement를 거부·제외하고 결정적인 baseline을 생성하며, 검증은 로컬 Supabase와 데이터 없는 임시 remote branch에서 수행한다. Production migration history 교체와 JWT 회전은 이 계획에 포함하지 않는다.

**Tech Stack:** Node.js ESM, `node:test`, Supabase CLI 2.90+, PostgreSQL 15, Supabase Management API, SQL

## Global Constraints

- Production project `xtijtefcycoeqludlngc`에는 read-only Management API query만 허용한다.
- Production schema, data, migration history, JWT/API keys, Edge Functions 및 설정을 변경하지 않는다.
- Production 데이터는 로컬 또는 remote branch로 복제하지 않는다.
- Baseline 입력은 `20260425161337_baseline_squash`와 그 이후 migration으로 한정하며, 이전 70개 불완전 migration은 생성 대상에서 제외한다.
- Secret 또는 일치한 secret 문자열을 stdout, stderr, fixture, Git 파일에 기록하지 않는다.
- Remote 검증 branch는 데이터 없이 ephemeral로 생성하고 검증 직후 삭제한다.
- Migration 파일은 반드시 `supabase migration new clean_baseline`으로 생성한다.
- PostgreSQL 15에서 전체 baseline과 후속 migration이 재생되어야 한다.

---

## File Structure

- `supabase/config.toml`: 로컬 PostgreSQL 15 검증 프로젝트 설정.
- `supabase/migrations/<generated>_clean_baseline.sql`: sanitizer가 생성한 단일 clean baseline.
- `scripts/supabase/assert-readonly-target.mjs`: production 접근을 read-only endpoint로 제한하고 secret 출력 없는 오류를 제공.
- `scripts/supabase/export-migration-history.mjs`: production migration statements를 메모리로 읽어 sanitizer에 전달.
- `scripts/supabase/sanitize-baseline.mjs`: statement 분류, 제외, 거부, 정규화 및 결정적 SQL 생성.
- `scripts/supabase/schema-fingerprint.mjs`: production과 검증 branch의 application schema catalog fingerprint 생성·비교.
- `scripts/supabase/verify-clean-baseline.mjs`: 로컬 reset, secret scan, 핵심 객체 검사 및 remote 검증 orchestration.
- `scripts/supabase/tests/*.test.mjs`: target guard, sanitizer, fingerprint allowlist 및 orchestration 회귀 테스트.
- `scripts/supabase/tests/fixtures/*.json`: 가짜 statement만 포함하는 테스트 fixture. 실제 production SQL과 secret은 금지.

### Task 1: Read-only Target Guard

**Files:**
- Create: `scripts/supabase/assert-readonly-target.mjs`
- Create: `scripts/supabase/tests/assert-readonly-target.test.mjs`

**Interfaces:**
- Consumes: `SUPABASE_ACCESS_TOKEN`, explicit project ref, explicit endpoint path.
- Produces: `assertReadonlyTarget({ projectRef, endpoint, method }): void`.

- [ ] **Step 1: Write failing guard tests**

Test that only `POST /v1/projects/xtijtefcycoeqludlngc/database/query/read-only` and log reads are accepted. Reject `/database/query`, migration endpoints, branch mutation endpoints, missing token, unknown project refs, and any error formatter containing token values.

- [ ] **Step 2: Run the focused test and confirm RED**

Run: `node --test scripts/supabase/tests/assert-readonly-target.test.mjs`

Expected: FAIL because `assert-readonly-target.mjs` does not exist.

- [ ] **Step 3: Implement the minimal guard**

Export `PRODUCTION_PROJECT_REF`, `assertReadonlyTarget`, and `redactError`. Compare exact method/path pairs; do not use substring allowlisting. Error output may include only the source name, HTTP status, and rule identifier.

- [ ] **Step 4: Run the focused test and confirm GREEN**

Run: `node --test scripts/supabase/tests/assert-readonly-target.test.mjs`

Expected: all tests pass with no token-like value in output.

- [ ] **Step 5: Commit**

Suggested commit: `test(supabase): guard production baseline reads`

Do not commit on the current non-standard branch without explicit approval.

### Task 2: Deterministic Baseline Sanitizer

**Files:**
- Create: `scripts/supabase/sanitize-baseline.mjs`
- Create: `scripts/supabase/tests/sanitize-baseline.test.mjs`
- Create: `scripts/supabase/tests/fixtures/migration-statements-safe.json`
- Create: `scripts/supabase/tests/fixtures/migration-statements-rejected.json`

**Interfaces:**
- Consumes: `{ version, name, statements: string[] }[]` in memory.
- Produces: `sanitizeBaseline(history): { sql: string, manifest: SanitizerManifest }`.
- `SanitizerManifest`: counts and SHA-256 hashes only; never statement text.

- [ ] **Step 1: Write failing sanitizer tests**

Cover deterministic ordering, PostgreSQL 17 `transaction_timeout`, `supabase_functions` references, `auth|storage|realtime|extensions|vault|net|cron` managed-object creation, dump owner/ACL/tablespace metadata, `INSERT/COPY/setval`, production ref, `Bearer`, JWT shape, `service_role`, and secret-key patterns. Dangerous authentication material must cause a hard failure; known platform objects and dump metadata must be excluded with count-only manifest entries.

- [ ] **Step 2: Run sanitizer tests and confirm RED**

Run: `node --test scripts/supabase/tests/sanitize-baseline.test.mjs`

Expected: FAIL because sanitizer exports are missing.

- [ ] **Step 3: Implement statement classification and normalization**

Implement explicit ordered rules. Parse statements conservatively: when ownership is ambiguous, reject instead of guessing. Normalize line endings and trailing whitespace, join statements with `;\n\n`, and prepend a generated-file notice containing no source SQL.

- [ ] **Step 4: Prove secret matches never enter diagnostics**

Run fixtures containing sentinel JWTs and assert captured stdout/stderr contains rule identifiers such as `SECRET_JWT` but not sentinel values.

- [ ] **Step 5: Run sanitizer tests and confirm GREEN**

Run: `node --test scripts/supabase/tests/sanitize-baseline.test.mjs`

Expected: all tests pass; repeated safe input produces byte-identical SQL and manifest hashes.

- [ ] **Step 6: Commit**

Suggested commit: `feat(supabase): add deterministic baseline sanitizer`

Do not commit on the current non-standard branch without explicit approval.

### Task 3: Read-only Migration Export

**Files:**
- Create: `scripts/supabase/export-migration-history.mjs`
- Create: `scripts/supabase/tests/export-migration-history.test.mjs`

**Interfaces:**
- Consumes: target guard and `fetch` implementation.
- Produces: `fetchMigrationHistory({ token, fetchImpl }): Promise<MigrationRecord[]>` and `generateBaseline({ outputPath }): Promise<SanitizerManifest>`.

- [ ] **Step 1: Write failing API boundary tests**

Use a fake `fetch` to assert exact URL, POST method, read-only endpoint, schema-qualified SQL, response shape validation, and no raw response logging. Reject missing `version`, `name`, or non-array `statements`.

- [ ] **Step 2: Run export tests and confirm RED**

Run: `node --test scripts/supabase/tests/export-migration-history.test.mjs`

Expected: FAIL because exporter does not exist.

- [ ] **Step 3: Implement in-memory export**

Query `supabase_migrations.schema_migrations` ordered by `version`. Require exactly one `20260425161337_baseline_squash`, discard earlier records, and pass that record plus later records to `sanitizeBaseline`; never persist raw production statements. Write only sanitized output via an atomic temporary-file rename after every rejection rule passes.

- [ ] **Step 4: Run export tests and confirm GREEN**

Run: `node --test scripts/supabase/tests/export-migration-history.test.mjs`

Expected: all tests pass and failed sanitization leaves the previous output untouched.

- [ ] **Step 5: Commit**

Suggested commit: `feat(supabase): export baseline through readonly api`

Do not commit on the current non-standard branch without explicit approval.

### Task 4: Create Local Supabase Project and Baseline

**Files:**
- Create: `supabase/config.toml`
- Create: `supabase/migrations/<generated>_clean_baseline.sql`
- Modify: `.gitignore` only if generated transient files are not already excluded.

**Interfaces:**
- Consumes: Task 3 generator.
- Produces: PostgreSQL 15-compatible local Supabase project and clean baseline migration.

- [ ] **Step 1: Discover CLI flags and initialize configuration**

Run `supabase init --help`, then initialize only if `supabase/config.toml` is absent. Pin local project settings to the CLI-supported PostgreSQL 15 release and disable seed data.

- [ ] **Step 2: Create the migration through the CLI**

Run: `supabase migration new clean_baseline`

Capture the generated path; do not invent the timestamp.

- [ ] **Step 3: Generate sanitized SQL into the CLI-created file**

Run the exporter with `SUPABASE_ACCESS_TOKEN` supplied through the environment and the generated path as output. Output only manifest counts and hashes.

- [ ] **Step 4: Run static secret and platform-object scans**

Reject matches for the production ref, `Bearer`, JWT three-segment shape, `service_role`, `sb_secret_`, `supabase_functions`, and `SET transaction_timeout` without printing the matching text.

- [ ] **Step 5: Run local reset**

Run: `supabase start` followed by `supabase db reset --local`

Expected: exit 0 with every migration applied. If Docker/local Supabase is unavailable, stop before creating a remote branch.

- [ ] **Step 6: Commit**

Suggested commit: `feat(supabase): add replayable clean baseline`

Do not commit on the current non-standard branch without explicit approval.

### Task 5: Schema Fingerprint and Local Equivalence

**Files:**
- Create: `scripts/supabase/schema-fingerprint.mjs`
- Create: `scripts/supabase/tests/schema-fingerprint.test.mjs`

**Interfaces:**
- Consumes: production read-only Management API and local `psql` catalog query results.
- Produces: normalized hashes for tables, columns, constraints, indexes, RLS flags/policies, functions, and triggers plus an allowlisted diff.

- [ ] **Step 1: Write failing fingerprint tests**

Use fake catalog rows to prove ordering is deterministic, platform schemas and branch-specific webhook triggers are excluded, and any missing application object fails the comparison.

- [ ] **Step 2: Run fingerprint tests and confirm RED**

Run: `node --test scripts/supabase/tests/schema-fingerprint.test.mjs`

Expected: FAIL because fingerprint implementation is absent.

- [ ] **Step 3: Implement catalog queries and normalization**

Use schema-qualified `pg_catalog` and `information_schema` references. Return object identifiers and hashes, not full definitions, in diagnostics. The only allowed differences are managed schemas, branch URL/secret webhook triggers, data, sequence values, and migration bookkeeping.

- [ ] **Step 4: Compare production and local fingerprints**

Run the production query via the guarded read-only endpoint and local query via the local database URL. Confirm no unallowlisted difference.

- [ ] **Step 5: Run all Node tests**

Run: `node --test scripts/supabase/tests/*.test.mjs`

Expected: all tests pass.

- [ ] **Step 6: Commit**

Suggested commit: `test(supabase): verify baseline schema equivalence`

Do not commit on the current non-standard branch without explicit approval.

### Task 6: Ephemeral Remote Branch Verification

**Files:**
- Create: `scripts/supabase/verify-clean-baseline.mjs`
- Create: `scripts/supabase/tests/verify-clean-baseline.test.mjs`

**Interfaces:**
- Consumes: Supabase CLI, sanitizer manifest, fingerprint comparison.
- Produces: exit 0 only after branch migration success, API reachability, fingerprint match, and confirmed deletion.

- [ ] **Step 1: Write failing orchestration tests**

Mock CLI execution and cover create failure, `MIGRATIONS_FAILED`, timeout, fingerprint mismatch, and cleanup on every exit path. Assert `--with-data` is never present and branch names begin with `verify/clean-baseline-`.

- [ ] **Step 2: Run orchestration tests and confirm RED**

Run: `node --test scripts/supabase/tests/verify-clean-baseline.test.mjs`

Expected: FAIL because verifier does not exist.

- [ ] **Step 3: Implement verifier with guaranteed cleanup**

Create a non-persistent, data-less branch; poll status with bounded retries; query migration state without printing branch credentials; compare fingerprints; then delete in a `finally` path. Verify deletion by listing branches.

- [ ] **Step 4: Run orchestration tests and confirm GREEN**

Run: `node --test scripts/supabase/tests/verify-clean-baseline.test.mjs`

Expected: all tests pass, including cleanup assertions.

- [ ] **Step 5: Execute remote verification**

Run the verifier against parent project `xtijtefcycoeqludlngc`. Expected final branch status is migration success/healthy, API returns unauthenticated `401`, fingerprint has no unallowlisted differences, and the verification branch no longer appears in `supabase branches list`.

- [ ] **Step 6: Commit**

Suggested commit: `test(supabase): verify clean baseline remotely`

Do not commit on the current non-standard branch without explicit approval.

### Task 7: Final Security and Production-No-Change Verification

**Files:**
- Modify only files identified above if verification reveals a defect.

**Interfaces:**
- Consumes: all generated artifacts and production read-only fingerprints.
- Produces: evidence that clean baseline is ready for a separately approved migration-history cutover.

- [ ] **Step 1: Run complete test suite**

Run: `node --test scripts/supabase/tests/*.test.mjs`

Expected: zero failures.

- [ ] **Step 2: Run local database verification from empty state**

Run: `supabase db reset --local` and `supabase migration list --local`.

Expected: baseline and every retained migration are applied.

- [ ] **Step 3: Run Supabase advisors on the local/verification database**

Run CLI commands discovered through `supabase db advisors --help`, targeting only local or ephemeral verification resources. Do not target production.

- [ ] **Step 4: Re-run secret scans without echoing matches**

Scan all created files for JWT, bearer authorization, production ref/URL, service-role and secret-key patterns. Report only rule names and file counts; expected count is zero.

- [ ] **Step 5: Prove production state was not changed**

Read production project status, migration-history count/hash, and application schema fingerprint through read-only endpoints. Compare them with pre-implementation snapshots captured before Task 4. Expected: identical values and `ACTIVE_HEALTHY`.

- [ ] **Step 6: Verify no remote branch remains**

Run: `supabase branches list --project-ref xtijtefcycoeqludlngc -o json`

Expected: no `verify/clean-baseline-*` branch.

- [ ] **Step 7: Prepare, but do not execute, cutover instructions**

Document the exact migration-history change, rollback material, and approval gates needed to adopt the baseline later. Do not alter production or rotate keys.

- [ ] **Step 8: Commit**

Suggested commit: `docs(supabase): document clean baseline verification`

Do not commit on the current non-standard branch without explicit approval.
