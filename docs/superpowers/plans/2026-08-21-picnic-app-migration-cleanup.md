# PICNIC App Misowned Migration Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the PICNIC-2056 database migration and pgTAP test incorrectly merged into `picnic-app` while preserving the clean baseline and documenting repository ownership.

**Architecture:** Use the existing `fix/supabase-migration-history` investigation worktree. Delete only the two files introduced by `picnic-app#170`; retain the ownership spec and keep the Supabase Preview configuration failure as a separate issue.

**Tech Stack:** Git, Supabase project layout, GitHub CLI

**Spec:** `docs/superpowers/specs/2026-08-21-anti-abuse-migration-ownership-correction-design.md`

## Global Constraints

- Do not modify the clean baseline or PICNIC-PROD migration history.
- Do not remove unrelated Supabase files from `picnic-app`.
- Merge this cleanup only after the equivalent `picnic-supabase` migration PR is green and durably contains the 48-hour implementation.
- Do not treat the existing Supabase Preview ownership/configuration failure as fixed by deleting the two files.

---

### Task 1: Add a failing ownership check and remove misowned files

**Files:**
- Delete: `supabase/migrations/20260821072611_extend_anti_abuse_block_to_48_hours.sql`
- Delete: `supabase/tests/anti_abuse_block_duration.test.sql`
- Keep: `docs/superpowers/specs/2026-08-21-anti-abuse-migration-ownership-correction-design.md`
- Create: `scripts/check_supabase_migration_ownership.sh` only if the repository already has an equivalent executable policy-check pattern; otherwise use a one-off verification command and do not add tooling.

**Interfaces:**
- Consumes: merge commit from `picnic-app#170`
- Produces: app repository without the misowned migration/test

- [ ] **Step 1: Verify the files and commit provenance**

Run:

```bash
git show --stat --oneline e53292cd1021bcfdb4b9059c4523cf88a29d14d5
git ls-tree -r --name-only HEAD | rg '20260821072611_extend_anti_abuse_block_to_48_hours|anti_abuse_block_duration.test.sql'
```

Expected: exactly the migration and test introduced by PR #170 are identified.

- [ ] **Step 2: Establish the failing ownership check**

Run:

```bash
test ! -e supabase/migrations/20260821072611_extend_anti_abuse_block_to_48_hours.sql
test ! -e supabase/tests/anti_abuse_block_duration.test.sql
```

Expected: command fails before cleanup because both files exist.

- [ ] **Step 3: Delete only the misowned files**

Use a patch that deletes the two exact files. Do not delete `supabase/tests/`, the clean baseline, other migrations, or the ownership spec.

- [ ] **Step 4: Verify GREEN and absence of references**

Run:

```bash
test ! -e supabase/migrations/20260821072611_extend_anti_abuse_block_to_48_hours.sql
test ! -e supabase/tests/anti_abuse_block_duration.test.sql
rg -n "enforce_anti_abuse_block_expiry|anti_abuse_block_duration" . \
  -g '!docs/superpowers/specs/2026-08-21-anti-abuse-migration-ownership-correction-design.md' \
  -g '!docs/superpowers/plans/2026-08-21-*.md'
git diff --check
```

Expected: file assertions pass; `rg` returns no runtime/test references; diff check passes.

- [ ] **Step 5: Commit the cleanup**

Run:

```bash
git add -A supabase/migrations/20260821072611_extend_anti_abuse_block_to_48_hours.sql \
  supabase/tests/anti_abuse_block_duration.test.sql \
  docs/superpowers/specs/2026-08-21-anti-abuse-migration-ownership-correction-design.md \
  docs/superpowers/plans/2026-08-21-picnic-*.md
git diff --cached --check
git commit -m "fix(supabase): restore database migration ownership"
```

Expected: commit contains the two deletions and approved ownership documentation only.

### Task 2: Review and cleanup PR after owner-repository readiness

**Files:**
- Review: `origin/main...HEAD`

**Interfaces:**
- Consumes: green `picnic-supabase` owner PR and app cleanup commit
- Produces: reviewable `picnic-app` cleanup PR

- [ ] **Step 1: Confirm the owner PR is green**

Resolve the open owner PR from its exact branch, then inspect it:

```bash
OWNER_PR=$(gh pr list --repo charlie0421/picnic-supabase \
  --head fix/anti-abuse-block-48-hours --state open --json number --jq '.[0].number')
test -n "$OWNER_PR"
gh pr view "$OWNER_PR" --repo charlie0421/picnic-supabase \
  --json state,mergeable,mergeStateStatus,statusCheckRollup,url
```

Expected: owner PR contains the migration/test and all required checks pass. Do not proceed if it is absent or failing.

- [ ] **Step 2: Run fresh cleanup verification**

Run the file-absence and reference commands from Task 1 Step 4, then:

```bash
git status --short --branch
git diff origin/main...HEAD --check
```

Expected: clean committed tree and intended diff only.

- [ ] **Step 3: Request opposite-provider Frontier review**

Give the reviewer the spec, owner PR URL/status, app diff, and verification output. Require explicit confirmation that the clean baseline and unrelated Supabase content remain intact.

Expected: no unresolved Critical or Important findings; fixes receive one re-review.

- [ ] **Step 4: Push and create the app cleanup PR**

Run:

```bash
git push -u origin fix/supabase-migration-history
gh pr create --base main --head fix/supabase-migration-history \
  --title "fix(supabase): restore database migration ownership" \
  --body $'## Summary\n\n- remove the PICNIC-2056 database migration and pgTAP test from the app repository\n- document that production database migrations are owned by picnic-supabase\n- preserve the app clean baseline and unrelated Supabase content\n\n## Verification\n\n- misowned files absent\n- no remaining runtime references\n- git diff check passes\n\nThe replacement migration is reviewed in the linked picnic-supabase PR. The picnic-app Supabase Preview ownership/configuration failure remains separate.'
```

Expected: PR URL returned. Do not merge automatically until the owner migration PR is merged and the user confirms the required preview/check gate.
