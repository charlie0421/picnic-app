# PICNIC-2232 Fullscreen Expiry Dialog Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the rounded, height-limited expiry policy popup with the app's existing edge-to-edge fullscreen dialog while preserving its content and state behavior.

**Architecture:** Route `showUsagePolicyDialog` through the shared `showFullScreenDialog` helper and make `UsagePolicyPopup` render a `FullScreenDialog`. Keep the existing policy body and its single scroll controller, but give it the full viewport below a safe, close-button-aware title area.

**Tech Stack:** Flutter, Riverpod, flutter_test golden tests

---

### Task 1: Pin the fullscreen contract with a failing widget test

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart`

**Step 1: Write the failing test**

Extend the dialog-opening test to assert:

- one `FullScreenDialog` is present;
- no `LargePopupWidget` is present;
- tapping the fullscreen close icon removes the dialog route.

**Step 2: Run the focused test and confirm RED**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart --plain-name "renders fullscreen dialog and closes from its close button"
```

Expected: FAIL because the current implementation still renders `LargePopupWidget`.

### Task 2: Replace the rounded popup shell

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart`

**Step 1: Implement the minimum shell change**

- Replace the direct `showGeneralDialog` scale/fade route with `showFullScreenDialog`.
- Replace `LargePopupWidget` and the `0.82 * height` constraint with `FullScreenDialog`.
- Place the existing title and state-dependent body in a `SafeArea`.
- Reserve horizontal space beside the shared circular close button.
- Keep the existing `_ScrollBody`, providers, login handling, loading state, error state, copy, calculations, and disclosure state unchanged.

**Step 2: Run the focused test and confirm GREEN**

Run the command from Task 1.

Expected: PASS.

**Step 3: Run all dialog behavior tests**

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart
```

Expected: PASS.

### Task 3: Adapt layout assertions to the fullscreen viewport

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart`

**Step 1: Replace shell-specific finders**

Use `FullScreenDialog` as the shell boundary and remove assertions that encode rounded-card clipping or the former height cap. Preserve assertions for:

- one vertical scroll area;
- no Flutter overflow exceptions at supported sizes and text scales;
- visible content staying within the fullscreen viewport;
- disclosure auto-scroll and bottom reachability.

**Step 2: Run the layout suite**

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart
```

Expected: PASS at 320x568, 360x640, 390x844, and large text scale.

### Task 4: Replace rounded-popup goldens with fullscreen goldens

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart`
- Modify: `picnic_lib/test/goldens/usage_policy_dialog_*.png`

**Step 1: Capture the fullscreen shell**

Change golden finders from `LargePopupWidget` to `FullScreenDialog` and make the test host reflect a full white route rather than a centered popup over a dark scrim.

**Step 2: Regenerate goldens**

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart --update-goldens
```

Expected: all nine reference PNGs are updated to show square, edge-to-edge fullscreen content.

**Step 3: Verify the regenerated goldens**

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: PASS.

Visually inspect at least:

- `usage_policy_dialog_ko_390x844.png`;
- `usage_policy_dialog_ko_320x568_collapsed.png`;
- `usage_policy_dialog_ko_390x844_scale1_3.png`.

### Task 5: Verify, review, and update the PR

**Files:**
- Review all changed production, test, spec, and golden files.

**Step 1: Format and analyze**

```bash
cd picnic_lib
dart format lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
flutter analyze \
  lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: no issues in the changed scope.

**Step 2: Run the focused suites**

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: PASS.

**Step 3: Run the full suite**

```bash
cd picnic_lib
flutter test
```

Expected: all tests pass, with only the repository's known skips.

**Step 4: Commit and push**

```bash
git add docs/superpowers/specs/2026-07-31-picnic-2232-fullscreen-expiry-dialog-design.md \
  docs/superpowers/plans/2026-07-31-picnic-2232-fullscreen-expiry-dialog.md \
  picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart \
  picnic_lib/test/goldens/usage_policy_dialog_*.png
git commit -m "fix(store): use fullscreen expiry dialog"
git push
```

**Step 5: Request independent PR re-review**

Review the final diff against the approved fullscreen design and report any blocking or important findings before asking for merge approval.
