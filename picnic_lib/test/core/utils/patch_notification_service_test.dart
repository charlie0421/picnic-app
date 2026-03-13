import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/patch_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PatchNotificationService', () {
    group('checkAndClearPatchApplied', () {
      test('returns false when shorebird updater fails in test environment',
          () async {
        // In test env, updater.readCurrentPatch() will throw
        // because shorebird code push is not available.
        // The catch block returns false.
        final result = await PatchNotificationService.checkAndClearPatchApplied();
        expect(result, isFalse);
      });

      test('returns false on multiple calls', () async {
        final result1 =
            await PatchNotificationService.checkAndClearPatchApplied();
        final result2 =
            await PatchNotificationService.checkAndClearPatchApplied();
        expect(result1, isFalse);
        expect(result2, isFalse);
      });
    });

    group('saveCurrentPatchNumber', () {
      test('completes without error when shorebird not available', () async {
        // updater.readCurrentPatch() will throw, caught silently
        await PatchNotificationService.saveCurrentPatchNumber();
      });

      test('can be called multiple times safely', () async {
        await PatchNotificationService.saveCurrentPatchNumber();
        await PatchNotificationService.saveCurrentPatchNumber();
        await PatchNotificationService.saveCurrentPatchNumber();
      });
    });

    // Note: showDownloadCompleteNotification tests are skipped because
    // SnackbarUtil.info() accesses AppColors which requires Environment._config
    // to be initialized (not available in unit test environment).

    group('resetSavedPatchNumber', () {
      test('completes without error', () async {
        await PatchNotificationService.resetSavedPatchNumber();
      });

      test('can be called multiple times', () async {
        await PatchNotificationService.resetSavedPatchNumber();
        await PatchNotificationService.resetSavedPatchNumber();
      });

      test('removes saved patch number from SharedPreferences', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_applied_patch_number', 5);

        await PatchNotificationService.resetSavedPatchNumber();

        final value = prefs.getInt('last_applied_patch_number');
        expect(value, isNull);
      });

      test(
          'checkAndClearPatchApplied after reset still returns false in test env',
          () async {
        await PatchNotificationService.resetSavedPatchNumber();
        final result =
            await PatchNotificationService.checkAndClearPatchApplied();
        expect(result, isFalse);
      });
    });

    group('SharedPreferences interaction', () {
      test('_lastPatchNumberKey uses correct key', () async {
        // Verify the key indirectly by setting a value and checking after reset
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_applied_patch_number', 42);
        expect(prefs.getInt('last_applied_patch_number'), 42);

        await PatchNotificationService.resetSavedPatchNumber();
        expect(prefs.getInt('last_applied_patch_number'), isNull);
      });
    });
  });
}
