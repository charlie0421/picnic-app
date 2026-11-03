# Anti-abuse Migration Ownership Correction Design

## Context

PICNIC-2056 requires newly created anti-abuse blocks to last at least 48 hours instead of 24 hours. PR `picnic-app#170` implemented the database migration and pgTAP coverage inside `picnic-app`, but the repository's existing architecture assigns reproducible production database migrations to `picnic-supabase`.

The failed `Supabase Preview` check on the merge commit reported `Remote migration versions not found in local migrations directory`. Investigation confirmed that this is not a small migration-history gap: PICNIC-PROD contains the full historical migration chain, while `picnic-app` intentionally contains a clean baseline for local and temporary-branch reproduction. Production migration history must not be rewritten to match the app repository.

## Goals

- Move the PICNIC-2056 database change and its pgTAP regression coverage to `picnic-supabase`.
- Remove the incorrectly owned migration and test from `picnic-app`.
- Preserve PICNIC-PROD migration history and existing production data.
- Keep the 48-hour behavior unchanged: newly inserted expiring `blocked` decisions last at least 48 hours, longer and permanent blocks are preserved, `suspect` remains non-expiring, and existing rows are not extended retroactively.
- Separate the `picnic-app` Supabase Preview configuration failure from the database behavior change.

## Non-goals

- Do not run `supabase migration repair` against PICNIC-PROD.
- Do not rewrite, squash, delete, or backfill production migration-history rows.
- Do not deploy or apply SQL to production as part of implementation or PR creation.
- Do not change Flutter behavior.
- Do not fix the repository-level Supabase Preview integration in the same PRs.

## Repository Ownership

### `picnic-supabase`

Create a new top-level Orca worktree from `origin/main` on a policy-compliant `fix/anti-abuse-block-48-hours` branch. Add a newly generated Supabase migration containing the trigger function and trigger, plus pgTAP tests following that repository's current conventions. Use the latest `origin/main`, not the dirty and outdated primary checkout.

### `picnic-app`

Use the existing investigation worktree on `fix/supabase-migration-history`. Remove only the migration and pgTAP test introduced by PR #170. Retain the clean baseline and unrelated Supabase files. Commit this design document with the ownership correction so the reason for removing the files remains durable.

## Data and Deployment Flow

1. `picnic-supabase` migration inserts a `BEFORE INSERT` trigger on `public.ip_block_decisions`.
2. New expiring `blocked` rows with less than 48 hours remaining are raised to 48 hours from the current statement timestamp.
3. Rows already at or above 48 hours, permanent blocks with `NULL expires_at`, and `suspect` rows are unchanged.
4. The trigger does not run on updates, so existing rows are not extended retroactively.
5. The migration is reviewed and merged through `picnic-supabase`; production application remains a separate approved deployment action.

## Safety and Error Handling

- The migration function uses `SECURITY INVOKER`, an empty `search_path`, and revoked public execution privileges.
- The migration is additive and does not update existing rows.
- A failed local reset, pgTAP run, migration-list comparison, or preview check blocks PR merge.
- Any need to alter production migration history or apply SQL remotely stops the workflow and requires separate explicit approval.
- Existing user changes in the primary `picnic-supabase` checkout are not touched or copied.

## Testing

The `picnic-supabase` pgTAP suite must verify:

1. A 24-hour expiring block becomes approximately 48 hours.
2. `suspect` remains non-expiring.
3. A block longer than 48 hours is not shortened.
4. A permanent block remains non-expiring.
5. A pre-existing short block is not extended by a later update.

Run the repository's documented local database reset and SQL test commands, database lint/advisors where supported, and `git diff --check`. The `picnic-app` cleanup PR must verify that only the two incorrectly owned files are removed and that no remaining code references them.

## Review and Integration

- Use Frontier cross-provider review because the change concerns production database migration ownership.
- Create separate PRs for `picnic-supabase` implementation and `picnic-app` cleanup.
- Merge the database-owner PR first. Merge the app cleanup PR only after the owner PR is green and the 48-hour migration exists durably in `picnic-supabase`.
- Do not mark PICNIC-2056 operationally complete until production application is separately confirmed.
