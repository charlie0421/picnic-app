import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/patch_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PatchNotificationService - showDownloadCompleteNotification', () {
    test('showDownloadCompleteNotification completes without error', () {
      // This calls SnackbarUtil.info which uses the scaffoldMessengerKey.
      // In test env without a MaterialApp, it will try to show but won't crash.
      // We just verify it does not throw.
      expect(
        () => PatchNotificationService.showDownloadCompleteNotification(
            '업데이트가 준비되었습니다'),
        returnsNormally,
      );
    });

    test('showDownloadCompleteNotification with empty message', () {
      expect(
        () => PatchNotificationService.showDownloadCompleteNotification(''),
        returnsNormally,
      );
    });

    test('showDownloadCompleteNotification with long message', () {
      final longMessage = 'A' * 500;
      expect(
        () => PatchNotificationService.showDownloadCompleteNotification(
            longMessage),
        returnsNormally,
      );
    });
  });

  group('PatchNotificationService - wasPatchApplied edge cases', () {
    test('returns true when current is larger than last', () {
      expect(
        PatchNotificationService.wasPatchApplied(
          currentPatchNumber: 10,
          lastPatchNumber: 5,
        ),
        isTrue,
      );
    });

    test('returns true when current is smaller than last (rollback)', () {
      expect(
        PatchNotificationService.wasPatchApplied(
          currentPatchNumber: 1,
          lastPatchNumber: 10,
        ),
        isTrue,
      );
    });

    test('returns false when both are zero', () {
      expect(
        PatchNotificationService.wasPatchApplied(
          currentPatchNumber: 0,
          lastPatchNumber: 0,
        ),
        isFalse,
      );
    });
  });

  group('PatchNotificationService - SharedPreferences integration', () {
    test('resetSavedPatchNumber clears stored value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_applied_patch_number', 10);
      expect(prefs.getInt('last_applied_patch_number'), 10);

      await PatchNotificationService.resetSavedPatchNumber();
      expect(prefs.getInt('last_applied_patch_number'), isNull);
    });

    test('saveCurrentPatchNumber handles shorebird unavailability', () async {
      // In test env, updater.readCurrentPatch() will throw.
      // The method should catch the error silently.
      await PatchNotificationService.saveCurrentPatchNumber();

      // Verify nothing was stored (since readCurrentPatch failed)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_applied_patch_number'), isNull);
    });

    test('checkAndClearPatchApplied handles shorebird unavailability',
        () async {
      // Set a previous value
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_applied_patch_number', 3);

      // In test, updater.readCurrentPatch() throws, so catch returns false
      final result =
          await PatchNotificationService.checkAndClearPatchApplied();
      expect(result, isFalse);
    });
  });
}
