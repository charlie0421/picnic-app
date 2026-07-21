# Edge JWT Session Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recover voting requests once after an authentication 401 and replace raw JWT errors with a safe re-login message.

**Architecture:** A pure classifier identifies recoverable authentication failures. A small retry coordinator keeps auth retry state separate from existing 429 retry state and injects refresh/invoke callbacks for deterministic tests; both voting dialogs use it.

**Tech Stack:** Flutter, Dart, Supabase Flutter 2.x, flutter_test, Sentry

## Global Constraints

- Retry authentication at most once per vote submission.
- Never retry after a 2xx response or for 400, 403, 429, or 5xx responses.
- Never log or display bearer tokens, JWT claims, user IDs, or raw `Invalid JWT` messages.
- Preserve existing optimistic update, rollback, loading and 429 backoff behavior.

---

### Task 1: Authentication failure classifier and retry coordinator

**Files:**
- Create: `picnic_lib/lib/core/services/auth/edge_auth_retry.dart`
- Create: `picnic_lib/test/core/services/auth/edge_auth_retry_test.dart`

**Interfaces:**
- Produces: `bool isRecoverableEdgeAuthFailure(Object error)`.
- Produces: `Future<T> invokeWithAuthRecovery<T>({required Future<T> Function() invoke, required Future<bool> Function() refresh})`.
- Produces: `EdgeAuthRecoveryException` for refresh failure or the second authentication failure.

- [ ] **Step 1: Write failing tests** for legacy/asymmetric/generic auth 401, non-auth statuses, refresh success, refresh failure, second 401 and exact invoke/refresh call counts.
- [ ] **Step 2: Verify RED** with `cd picnic_lib && flutter test test/core/services/auth/edge_auth_retry_test.dart`; expect import/module failure.
- [ ] **Step 3: Implement minimal classifier/coordinator** using `FunctionException.status` and structured detail codes, never error-string interpolation into user-visible output.
- [ ] **Step 4: Verify GREEN** with the same test command.
- [ ] **Step 5: Commit** with `git add picnic_lib/lib/core/services/auth/edge_auth_retry.dart picnic_lib/test/core/services/auth/edge_auth_retry_test.dart && git commit -m "feat(auth): add one-shot edge session recovery"`.

### Task 2: General voting integration

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog_helper.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/voting/voting_dialog_helper_test.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/voting/voting_dialog_test.dart`
- Modify: localization ARB/generated files using the repository localization workflow

- [ ] **Step 1: Add failing tests** proving first auth 401 refreshes and retries once, second failure stops, non-auth errors do not refresh, and raw `Invalid JWT` is replaced by the localized re-login copy.
- [ ] **Step 2: Verify RED** with targeted voting dialog/helper tests.
- [ ] **Step 3: Wrap `_invokeVotingWithRetry` with auth recovery**, call `supabase.auth.refreshSession()`, retain the independent 429 retry counter, and map `EdgeAuthRecoveryException` to the re-login message.
- [ ] **Step 4: Add low-cardinality Sentry phases** `refresh_started`, `refresh_succeeded`, `refresh_failed`, `retry_failed` without request or identity data.
- [ ] **Step 5: Generate localization output** with the repository's existing `flutter gen-l10n` command and verify all supported locales compile.
- [ ] **Step 6: Verify GREEN** with targeted tests and `flutter analyze lib/presentation/widgets/vote/voting/voting_dialog.dart lib/core/services/auth/edge_auth_retry.dart`.
- [ ] **Step 7: Commit** with `git add picnic_lib && git commit -m "fix(vote): recover expired edge auth session"`.

### Task 3: JMA voting integration

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/voting/jma_voting_dialog.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/voting/jma_voting_dialog_test.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/voting/jma_voting_dialog_widget_test.dart`

- [ ] **Step 1: Add failing JMA tests** for one refresh/retry, refresh failure, second 401 and preservation of the existing 429 retry limit.
- [ ] **Step 2: Verify RED** with the two targeted JMA test files.
- [ ] **Step 3: Integrate the shared coordinator** without duplicating authentication classification and emit the `portal=jma` recovery tag.
- [ ] **Step 4: Verify GREEN** with all voting tests under `test/presentation/widgets/vote/voting`.
- [ ] **Step 5: Commit** with `git add picnic_lib/lib/presentation/widgets/vote/voting/jma_voting_dialog.dart picnic_lib/test/presentation/widgets/vote/voting && git commit -m "fix(vote): recover JMA edge auth session"`.

### Task 4: App regression verification

**Files:**
- Modify only if verification exposes a defect.

- [ ] **Step 1: Run** `cd picnic_lib && flutter test test/core/services/auth/edge_auth_retry_test.dart test/presentation/widgets/vote/voting` and require zero failures.
- [ ] **Step 2: Run** `cd picnic_lib && flutter analyze lib/core/services/auth/edge_auth_retry.dart lib/presentation/widgets/vote/voting` and require no new issues.
- [ ] **Step 3: Run `git diff --check` and secret scan** with `rg -n "Bearer eyJ|accessToken\}" picnic_lib/lib/core/services/auth picnic_lib/lib/presentation/widgets/vote/voting` and confirm no token logging was introduced.
- [ ] **Step 4: Record the verified commands and outcomes** in the PR body; no separate generated report file is required.

