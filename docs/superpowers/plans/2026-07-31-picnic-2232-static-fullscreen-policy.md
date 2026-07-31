# PICNIC-2232 Static Fullscreen Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Center the fullscreen expiry-policy title and render every policy section permanently expanded without disclosure controls.

**Architecture:** Keep `UsagePolicyPopup`, its Riverpod state branches, cards, and single `_ScrollBody`. Replace the stateful `_Disclosure` units with a stateless section builder and center the title in a symmetric close-button-safe area.

**Tech Stack:** Flutter, Riverpod, flutter_test, golden tests

## Global Constraints

- Keep the edge-to-edge white `FullScreenDialog` and shared SafeArea close button.
- Preserve providers, APIs, calculations, localization copy, cards, login states, loading states, and error states.
- Keep exactly one vertical `SingleChildScrollView`.
- All three policy section bodies must be visible immediately.
- No disclosure arrows, tap handlers, expansion animation, expansion state, reveal timers, or expansion-driven scrolling remain.

---

### Task 1: Pin centered-title and static-section behavior

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart`

**Interfaces:**
- Consumes: `UsagePolicyPopup`, existing localized policy strings
- Produces: behavioral tests for centered title and immediately visible section bodies

- [ ] **Step 1: Write failing widget tests**

Add a title test that obtains the `VoteCommonTitle` rectangle and asserts its
horizontal center equals the `UsagePolicyPopup` horizontal center within
`0.01` logical pixels.

Add a static-content test that asserts the expiry timing, example, and policy
body strings are present before any tap, and that disclosure arrow SVGs are
absent from the section headers.

- [ ] **Step 2: Run the focused tests to verify RED**

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart
```

Expected: FAIL because the title is biased left by asymmetric padding and the
timing/example sections are initially collapsed.

- [ ] **Step 3: Confirm each test catches the intended mutation**

The centered-title test must fail if asymmetric right-only close-button space
returns. The static-content test must fail if any section body is omitted
until interaction.

### Task 2: Replace disclosures with static sections

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart`

**Interfaces:**
- Consumes: existing `_timingRuleChildren`, `_exampleChildren`, `_policyChildren`
- Produces: `_PolicySection({required Key key, required String title, required List<Widget> children})`

- [ ] **Step 1: Center the title with symmetric reserved space**

Use equal horizontal padding large enough for the 48px close button plus its
15px edge offset. Keep the title `Align` centered so its center matches the
screen center:

```dart
padding: const EdgeInsets.fromLTRB(64, 24, 64, 16),
child: Center(
  child: VoteCommonTitle(
    title: localizations.expiring_bonus_candy_guide,
  ),
),
```

- [ ] **Step 2: Implement a stateless policy section**

Replace `_Disclosure` with:

```dart
class _PolicySection extends StatelessWidget {
  const _PolicySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: _t(AppTypo.body14B, AppColors.grey900, height: 1.20),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 3: Render all three sections statically**

Replace each `_Disclosure` call with `_PolicySection`, retaining the existing
keys, titles, child builders, order, and `_hairline` dividers. Remove
`initiallyExpanded`.

- [ ] **Step 4: Delete obsolete disclosure machinery**

Remove `_Disclosure`, `_DisclosureState`, `_growth`, `_open`, `_blockKey`,
`_revealTimer`, `_toggle`, `_reveal`, `AnimatedRotation`, `AnimatedSize`, and
the expansion-only `dart:async`, `dart:math`, and rendering imports if unused.

- [ ] **Step 5: Run focused tests to verify GREEN**

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart
```

Expected: PASS with all bodies visible immediately and no overflow.

- [ ] **Step 6: Commit**

```bash
git add \
  picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart
git commit -m "fix(store): show policy sections expanded"
```

### Task 3: Replace interaction goldens with static-content goldens

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart`
- Modify: `picnic_lib/test/goldens/usage_policy_dialog_*.png`

**Interfaces:**
- Consumes: static `UsagePolicyPopup`
- Produces: nine fullscreen PNG references without disclosure arrows

- [ ] **Step 1: Remove disclosure interaction helpers**

Delete `_openTimingRules` and all test taps. Rename expanded/collapsed test
descriptions to describe initial and scroll-position states. Keep the existing
size, locale, text-scale, empty-row, and bottom-scroll coverage.

- [ ] **Step 2: Regenerate all goldens**

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart \
  --update-goldens
```

Expected: PASS and nine changed PNGs showing all policy bodies immediately.

- [ ] **Step 3: Verify the regenerated goldens**

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: PASS.

- [ ] **Step 4: Visually inspect representative PNGs**

Inspect:

- `picnic_lib/test/goldens/usage_policy_dialog_ko_390x844.png`
- `picnic_lib/test/goldens/usage_policy_dialog_ko_320x568_collapsed.png`
- `picnic_lib/test/goldens/usage_policy_dialog_ko_390x844_scale1_3.png`

Confirm the title is centered, every section is expanded, no section arrows
remain, the close icon is correct, and small/large-text layouts scroll cleanly.

### Task 4: Verify and update PR #127

**Files:**
- Review all changed production, test, spec, plan, and golden files

**Interfaces:**
- Consumes: Tasks 1–3
- Produces: reviewed and pushed PR update ready for user visual approval

- [ ] **Step 1: Format and run scoped analysis**

```bash
cd picnic_lib
dart format \
  lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
flutter analyze \
  lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: no issues.

- [ ] **Step 2: Run focused tests**

```bash
cd picnic_lib
flutter test \
  test/presentation/dialogs/fullscreen_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart \
  test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run the complete Flutter suite**

```bash
cd picnic_lib
flutter test --reporter compact
```

Expected: all tests pass with only the repository's known skips.

- [ ] **Step 4: Commit remaining golden and plan changes**

```bash
git add \
  docs/superpowers/plans/2026-07-31-picnic-2232-static-fullscreen-policy.md \
  picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart \
  picnic_lib/test/goldens/usage_policy_dialog_*.png
git commit -m "test(store): update static policy goldens"
git push
```

- [ ] **Step 5: Request independent re-review**

Review the final PR diff against the approved design. Blocking and important
findings must be resolved before asking the user for visual approval and merge.
