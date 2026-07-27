# Final App Review Fix Report

## Outcome

- Added the `vote_auth_recovery` Sentry event with only `portal`, `phase`, and numeric HTTP `status` tags.
- Classified every `FunctionException` with status 401 as recoverable, independent of details format.
- Emitted `retry_failed` for every exception escaping the post-refresh retry while preserving the original error object and retry caps.
- Kept JMA implementation unchanged and documented its globally disabled, excluded/deferred status.

## TDD Evidence

### RED

Command:

```text
cd picnic_lib
flutter test test/presentation/widgets/vote/voting/voting_dialog_helper_test.dart
```

Observed expected compile failures because `VotingAuthRecoveryEvent`, `onRecovery`, and `authRecoveryTags` did not exist. This proved the new telemetry contract and post-refresh status behavior were not implemented yet.

### GREEN

Focused command:

```text
flutter test test/presentation/widgets/vote/voting/voting_dialog_helper_test.dart test/core/services/auth/edge_auth_retry_test.dart
```

Result: 61 tests passed before the final interaction case was added.

Full voting command:

```text
flutter test test/core/services/auth/edge_auth_retry_test.dart test/presentation/widgets/vote/voting
```

Result: 327 tests passed, zero failures.

## Coverage Added

- Table-driven 400, 403, and 500 first-response cases do not refresh and preserve the original `FunctionException` status.
- A 401 followed by refresh and a 429/backoff interaction succeeds without emitting `retry_failed` when the inner 429 retry recovers.
- A terminal post-refresh 429 emits `retry_failed` with status 429 and rethrows the same error object.
- Sentry tags are exactly `portal`, `phase`, and `status`; no exception, details, user, request, or token field is present.

## Static and Safety Checks

- Target analysis completed with five pre-existing findings in voting files: two `use_build_context_synchronously` infos and three `invalid_use_of_visible_for_testing_member` warnings. No finding points to the new auth recovery helper or telemetry code.
- `git diff --check`: clean.
- Secret scan found no bearer token or access-token logging. The existing vote request body still contains `user_id`; it is not included in telemetry.
- JMA source and tests have no diff.

## Scope Preservation

The optimistic update, failure rollback, loading cleanup, button re-enable flow, auth retry cap, and existing 429 retry cap were not changed. No deployment or push was performed.
