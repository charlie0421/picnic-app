# PICNIC Supabase Anti-abuse 48-hour Block Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the PICNIC-2056 48-hour automatic anti-abuse block behavior to the production database owner repository with executable regression coverage.

**Architecture:** Work in a new top-level `picnic-supabase` Orca worktree based on `origin/main`. Add one additive `BEFORE INSERT` trigger migration on `public.ip_block_decisions` and a focused pgTAP suite; never alter existing rows or production migration history.

**Tech Stack:** PostgreSQL 17, PL/pgSQL, pgTAP, Supabase CLI, Orca worktrees

**Spec:** `docs/superpowers/specs/2026-08-21-anti-abuse-migration-ownership-correction-design.md`

## Global Constraints

- Do not run `supabase migration repair` against PICNIC-PROD.
- Do not rewrite, squash, delete, backfill, or directly apply production migration-history rows.
- Do not deploy or apply SQL remotely in this implementation plan.
- Use `origin/main` from `picnic-supabase`; do not modify its dirty primary checkout.
- New expiring `blocked` decisions last at least 48 hours; longer and permanent blocks, `suspect`, and existing rows retain their existing semantics.

---

### Task 1: Create and validate the database-owner worktree

**Files:**
- Inspect: `/Users/charlie.hyun/Repositories/picnic-supabase/AGENTS.md`
- Inspect: `/Users/charlie.hyun/Repositories/picnic-supabase/CLAUDE.md`
- Inspect: `package.json`
- Inspect: `supabase/config.toml`
- Inspect: `supabase/tests/`

**Interfaces:**
- Consumes: `origin/main` of `charlie0421/picnic-supabase`
- Produces: an Orca-managed worktree on branch `fix/anti-abuse-block-48-hours`

- [ ] **Step 1: Refresh read-only repository metadata**

Run:

```bash
git -C /Users/charlie.hyun/Repositories/picnic-supabase fetch origin main
git -C /Users/charlie.hyun/Repositories/picnic-supabase status --short --branch
git -C /Users/charlie.hyun/Repositories/picnic-supabase rev-parse origin/main
```

Expected: fetch succeeds; the dirty primary checkout remains untouched; `origin/main` resolves.

- [ ] **Step 2: Create the top-level Orca worktree**

Run from an Orca-managed terminal:

```bash
orca worktree create --repo path:/Users/charlie.hyun/Repositories/picnic-supabase --name fix/anti-abuse-block-48-hours --no-parent --base-branch origin/main --setup run --comment "PICNIC-2056 48시간 DB 차단" --json
```

Expected: result contains a new absolute worktree path and `head` equal to the refreshed `origin/main` SHA. If Orca prefixes the Git branch, rename it inside the new worktree with `git branch -m fix/anti-abuse-block-48-hours` before any commit.

- [ ] **Step 3: Read repository-specific instructions and commands**

Run:

```bash
rg --files -g 'AGENTS.md' -g 'CLAUDE.md' -g 'package.json' -g 'supabase/config.toml'
sed -n '1,260p' package.json
find supabase/tests -maxdepth 2 -type f -print | sort | head -80
```

Expected: identify the exact local reset and pgTAP commands without guessing.

- [ ] **Step 4: Verify the clean baseline**

Run the repository's documented dependency setup, local DB reset, and existing database tests.

Expected: baseline passes. If it fails before any file changes, stop and report the exact pre-existing failures.

### Task 2: Add failing anti-abuse block-duration tests

**Files:**
- Create: `supabase/tests/anti_abuse_block_duration.test.sql`

**Interfaces:**
- Consumes: `public.ip_block_decisions` and the repository's pgTAP setup
- Produces: five behavioral assertions that fail without `public.enforce_anti_abuse_block_expiry()`

- [ ] **Step 1: Create the pgTAP test transaction**

Create a test that begins a transaction, sets `search_path = public, extensions`, calls `plan(5)`, and inserts complete `ip_block_decisions` fixtures for these literal cases:

```sql
-- 24-hour blocked row: expected 47:59 through 48:01 remaining
-- suspect row with NULL expiry: expected NULL
-- 72-hour blocked row: expected 71:59 through 72:01 remaining
-- permanent blocked row with NULL expiry: expected NULL
-- legacy 2-hour blocked row seeded while the new trigger is disabled,
-- then updated after the trigger is enabled: expected 1:59 through 2:01 remaining
```

Use unique `ip_hash` values prefixed with `pgtap-`, call `finish()`, and `rollback`.

- [ ] **Step 2: Run the focused test and verify RED**

Run the repository's documented pgTAP command targeting `supabase/tests/anti_abuse_block_duration.test.sql`.

Expected: the 48-hour assertion fails because the existing code stores approximately 24 hours. The other assertions may pass. A syntax, fixture, or missing-extension error is not an acceptable RED state.

- [ ] **Step 3: Commit the failing regression test**

Run:

```bash
git add supabase/tests/anti_abuse_block_duration.test.sql
git diff --cached --check
git commit -m "test(anti-abuse): cover 48-hour block duration"
```

Expected: one test-only commit.

### Task 3: Implement the additive trigger migration

**Files:**
- Create: the single file matching `supabase/migrations/*_extend_anti_abuse_block_to_48_hours.sql` generated by the CLI
- Test: `supabase/tests/anti_abuse_block_duration.test.sql`

**Interfaces:**
- Consumes: inserted `public.ip_block_decisions` rows
- Produces: `public.enforce_anti_abuse_block_expiry() returns trigger` and trigger `enforce_anti_abuse_block_expiry`

- [ ] **Step 1: Generate the migration using the CLI**

Run:

```bash
supabase migration new extend_anti_abuse_block_to_48_hours
```

Expected: one new timestamped migration file; do not invent its timestamp.

- [ ] **Step 2: Add the minimal implementation**

Write this migration body:

```sql
create or replace function public.enforce_anti_abuse_block_expiry()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  if new.decision = 'blocked'
     and new.expires_at is not null
     and new.expires_at < statement_timestamp() + interval '48 hours' then
    new.expires_at := statement_timestamp() + interval '48 hours';
  end if;

  return new;
end;
$function$;

comment on function public.enforce_anti_abuse_block_expiry() is
  'Ensures newly inserted, expiring anti-abuse blocks last at least 48 hours.';

revoke execute on function public.enforce_anti_abuse_block_expiry() from public;
revoke execute on function public.enforce_anti_abuse_block_expiry() from anon;
revoke execute on function public.enforce_anti_abuse_block_expiry() from authenticated;

drop trigger if exists enforce_anti_abuse_block_expiry
  on public.ip_block_decisions;

create trigger enforce_anti_abuse_block_expiry
before insert on public.ip_block_decisions
for each row
execute function public.enforce_anti_abuse_block_expiry();
```

- [ ] **Step 3: Reset the local DB and verify GREEN**

Run the repository's documented local reset command, then the focused pgTAP test.

Expected: all 5 assertions pass with no `not ok` or `Looks like you failed` output.

- [ ] **Step 4: Run the full database verification**

Run the repository's documented SQL test suite, `supabase db lint`, `supabase db advisors`, and:

```bash
git diff --check
supabase migration list --local
git status --short --branch
```

Expected: no new lint/advisor issues attributable to the migration; the new migration appears locally; only intended files are changed.

- [ ] **Step 5: Commit the implementation**

Run:

```bash
git add supabase/migrations/*_extend_anti_abuse_block_to_48_hours.sql
git diff --cached --check
git commit -m "fix(anti-abuse): extend block duration to 48 hours"
```

Expected: implementation commit contains only the generated migration.

### Task 4: Frontier review and owner-repository PR

**Files:**
- Review: the migration and test commits relative to `origin/main`

**Interfaces:**
- Consumes: green branch diff and exact test outputs
- Produces: reviewed `picnic-supabase` PR; no production deployment

- [ ] **Step 1: Run fresh final verification**

Run focused and full database tests again from the committed tree, plus `git diff origin/main...HEAD --check`.

Expected: all required checks pass on the exact commit to push.

- [ ] **Step 2: Request opposite-provider Frontier review**

Provide only the spec, `origin/main...HEAD` diff, relevant files, and test results. Require findings to include severity, file/line, failure condition, and minimal fix.

Expected: no unresolved Critical or Important findings; any fixes receive one re-review.

- [ ] **Step 3: Push and create the PR**

Run:

```bash
git push -u origin fix/anti-abuse-block-48-hours
gh pr create --base main --head fix/anti-abuse-block-48-hours \
  --title "fix(anti-abuse): extend block duration to 48 hours" \
  --body $'## Summary\n\n- enforce a minimum 48-hour expiry for newly inserted anti-abuse blocks\n- preserve longer, permanent, suspect, and pre-existing decisions\n- add five pgTAP regression cases\n\n## Verification\n\n- focused pgTAP suite: 5/5 pass\n- repository database suite: pass\n- database lint/advisors: no new findings\n\nJira: PICNIC-2056\n\nThis PR does not deploy or apply SQL to production.'
```

Expected: PR URL returned; keep the worktree for review feedback.

- [ ] **Step 4: Wait for owner-repository checks**

Resolve the PR number and wait for checks:

```bash
OWNER_PR=$(gh pr view --json number --jq .number)
gh pr checks "$OWNER_PR" --watch
```

Expected: all required checks pass. Stop on failure; do not merge or deploy automatically.
