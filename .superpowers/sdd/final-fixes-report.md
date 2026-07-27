# Candy reward receipt final fixes

## Scope

- Reject positive non-cotton `GRANTED` ad grants by returning `null`, matching
  the existing nullable adapter contract and ad host failure/no-receipt path.
- Replace assert-only receipt invariants with release-safe `ArgumentError`
  validation.
- Remove unused `CandyRewardReceipt.supportingMessageKey`.
- Preserve existing duplicate purchase coverage without adding a broad
  production seam solely for a state-level test.

## RED

Command:

```sh
cd picnic_lib
flutter test test/data/models/wallet/candy_reward_receipt_test.dart
```

Observed result: exit 1, five expected failures.

- Positive `starCandy` and `bonusStarCandy` grants returned a receipt instead
  of `null`.
- Zero and negative `grantedAmount` threw `_AssertionError` instead of
  `ArgumentError`.
- An empty receipt item list threw `_AssertionError` instead of
  `ArgumentError`.

An initial `fvm flutter test` attempt could not resolve dependencies because
that FVM SDK supplied Dart 3.5.0 while the package requires Dart `^3.9.0`.
The repository's active `flutter` is Flutter 3.41.4 / Dart 3.11.1 and was used
for all effective RED/GREEN verification.

## GREEN

Model command:

```sh
cd picnic_lib
flutter test test/data/models/wallet/candy_reward_receipt_test.dart
```

Observed result: exit 0, 10 tests passed.

Focused regression command:

```sh
cd picnic_lib
flutter test -r compact \
  test/data/models/wallet/candy_reward_receipt_test.dart \
  test/presentation/dialogs/candy_reward_receipt_dialog_test.dart \
  test/presentation/widgets/ad_reward_dialog_host_test.dart \
  test/presentation/providers/ad_reward_recovery_provider_test.dart \
  test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart \
  test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_logic_test.dart \
  test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart \
  test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart \
  test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_extended_test.dart
```

The first attempt exposed a missing generated
`picnic_lib/lib/l10n/app_localizations.dart`, not a product-code failure.
Running `flutter gen-l10n` from `picnic_app` restored ignored generated
localization sources. The rerun exited 0 with 174 passed and one pre-existing
skipped test.

Static verification:

```sh
cd picnic_lib
dart format \
  lib/data/models/wallet/candy_reward_receipt.dart \
  test/data/models/wallet/candy_reward_receipt_test.dart
dart analyze \
  lib/data/models/wallet/candy_reward_receipt.dart \
  test/data/models/wallet/candy_reward_receipt_test.dart
```

Observed result: both files formatted; analyzer reported `No issues found!`.

Repository verification:

```sh
git diff --check
rg -n "supportingMessageKey" picnic_lib picnic_app --glob '*.dart'
```

Observed result: clean diff check and no Dart consumers or declarations of
`supportingMessageKey`.

## Duplicate purchase state-test decision

A new direct `PurchaseStarCandyState` duplicate-update presentation test was
not added. The exact duplicate identity gate is already covered by
`PurchaseCampaignAttemptRegistry`: a completed transaction ID is tombstoned
and cannot bind to a later attempt. Exact single presentation and awaiting are
covered for both normal and late settlements by
`PurchaseSettlementPresentation`.

Driving the private state callback directly would require a test-only
refactor/DI seam for state-owned `PurchaseService`, platform-dependent
`Platform.isIOS` routing, navigator/provider state, timers, and native
in-app-purchase behavior. That is a broad refactor with more risk than the
requested final fixes, so the existing exact gate and presentation tests were
kept and included in the focused run rather than weakening assertions or
adding a misleading mock-only state test.

## Workspace hygiene

The l10n command also rewrote `picnic_lib/untranslated-messages.json`; that
generated side effect was restored before commit. Existing unrelated changes
under `picnic_app/config/dev.json`, `picnic_app/untranslated-messages.json`,
`.playwright-cli/`, and `output/` were not modified or staged.
