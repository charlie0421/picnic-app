# Shorebird Startup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve immediate Shorebird patch detection and restart prompting without allowing Shorebird native calls to block app startup.

**Architecture:** Disable Shorebird's engine-level automatic update so it cannot race the Dart API. Remove Shorebird from the blocking startup update service, then run one lazy, single-flight manual coordinator after the home UI is ready and on foreground resume.

**Tech Stack:** Flutter, Riverpod, `shorebird_code_push`, Shorebird release configuration, Flutter tests.

## Global Constraints

- No Supabase schema changes.
- No production deployment.
- Shorebird failures must never block splash completion or home entry.
- Patch detection, download, and restart prompting must remain available.

---

### Task 1: Remove Shorebird From Blocking Startup

**Files:**
- Modify: `picnic_app/shorebird.yaml`
- Modify: `picnic_lib/lib/core/services/update_service.dart`
- Test: `picnic_lib/test/core/services/update_service_test.dart`

**Interfaces:**
- Consumes: `checkUpdateProvider.future`
- Produces: `checkForUpdates(WidgetRef ref) -> Future<UpdateInfo?>` that only checks the store version.

- [ ] **Step 1: Write the failing test**

Add an injectable `storeUpdateCheck` callback to `checkForUpdates` and verify the callback result is returned without constructing or invoking a Shorebird updater.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/update_service_test.dart`

Expected: FAIL because `storeUpdateCheck` is not accepted.

- [ ] **Step 3: Implement minimal separation**

Set `auto_update: false`. Remove `ShorebirdUpdater` creation and patch status handling from `checkForUpdates`; retain only the store-version provider call.

- [ ] **Step 4: Run the test**

Run: `flutter test test/core/services/update_service_test.dart`

Expected: PASS.

### Task 2: Add a Single-Flight Manual Shorebird Coordinator

**Files:**
- Create: `picnic_lib/lib/core/services/shorebird_update_coordinator.dart`
- Test: `picnic_lib/test/core/services/shorebird_update_coordinator_test.dart`

**Interfaces:**
- Consumes: an adapter exposing check, update, current patch, and next patch operations.
- Produces: `ShorebirdUpdateCoordinator.run() -> Future<ShorebirdRunResult>`.

- [ ] **Step 1: Write failing concurrency and update tests**

Verify two simultaneous `run()` calls share one native check. Verify `outdated` triggers one download and returns `restartRequired`. Verify timeout returns an error result.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/core/services/shorebird_update_coordinator_test.dart`

Expected: FAIL because the coordinator does not exist.

- [ ] **Step 3: Implement the coordinator**

Use one lazily created updater adapter, cache the active Future, clear it on completion, and apply bounded check/download timeouts. Convert all errors into result values.

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/services/shorebird_update_coordinator_test.dart`

Expected: PASS.

### Task 3: Trigger Manual Update After Home Entry

**Files:**
- Modify: `picnic_app/lib/app.dart`
- Modify: `picnic_lib/lib/core/utils/shorebird_utils.dart`
- Test: `picnic_lib/test/core/services/shorebird_update_coordinator_test.dart`

**Interfaces:**
- Consumes: `ShorebirdUpdateCoordinator.run()`.
- Produces: patch provider updates that drive `PatchRestartDialogListener`.

- [ ] **Step 1: Add a failing result-mapping test**

Verify `restartRequired` updates the patch status needed by the existing restart dialog.

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/core/services/shorebird_update_coordinator_test.dart`

Expected: FAIL because result mapping is absent.

- [ ] **Step 3: Wire the coordinator**

After `_isAppInitialized` becomes true, start the coordinator without awaiting it. On app resume, invoke the same coordinator. Publish downloaded/restart-required states to the existing providers.

- [ ] **Step 4: Run relevant tests and analysis**

Run:

```bash
flutter test test/core/services/update_service_test.dart test/core/services/shorebird_update_coordinator_test.dart test/core/utils/startup_future_guard_test.dart
flutter analyze lib/core/services/update_service.dart lib/core/services/shorebird_update_coordinator.dart lib/core/utils/shorebird_utils.dart
```

Expected: tests pass; analysis has no new errors.

### Task 4: Build and Stage a TestFlight Release

**Files:**
- Modify: `picnic_app/pubspec.yaml`

- [ ] **Step 1: Bump the staging version**

Increment version and build number from the latest tag.

- [ ] **Step 2: Verify startup**

Run the staging app on the iOS simulator and confirm `_isAppInitialized=true`. Shorebird remains unavailable in simulator/debug by design.

- [ ] **Step 3: Commit and push**

Commit only implementation files and tests with a Conventional Commit message, then push the feature branch.

- [ ] **Step 4: Trigger staging deployment**

Create and push the matching `picnic-v<version>+<build>` tag. Confirm Codemagic creates iOS and Android staging builds.
