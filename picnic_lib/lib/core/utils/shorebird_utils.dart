import 'package:picnic_lib/core/services/shorebird_update_coordinator.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/patch_notification_service.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:universal_platform/universal_platform.dart';

String? _downloadCompleteMessage;

typedef PatchStatusCallback = void Function(ShorebirdPatchEvent event);

enum ShorebirdPatchEvent {
  checking,
  downloading,
  downloadCompleted,
  restartPending,
  upToDate,
  error,
}

PatchStatusCallback? _onPatchStatusChanged;

class PatchStatusCheckResult {
  final shorebird.UpdateStatus status;
  final int? currentPatchNumber;
  final int? nextPatchNumber;

  const PatchStatusCheckResult({
    required this.status,
    this.currentPatchNumber,
    this.nextPatchNumber,
  });
}

enum PatchStatusError { webUnsupported, generic }

class PatchStatusException implements Exception {
  final PatchStatusError code;
  final String? message;

  const PatchStatusException(this.code, {this.message});

  @override
  String toString() => 'PatchStatusException(code: $code, message: $message)';
}

class ShorebirdUtils {
  static Future<bool> isPatchingAvailable() async => !UniversalPlatform.isWeb;

  static void setOnPatchStatusChanged(PatchStatusCallback? callback) {
    _onPatchStatusChanged = callback;
  }

  static ShorebirdPatchEvent eventForResult(ShorebirdRunResult result) {
    switch (result.state) {
      case ShorebirdRunState.restartRequired:
        return ShorebirdPatchEvent.restartPending;
      case ShorebirdRunState.upToDate:
      case ShorebirdRunState.unavailable:
        return ShorebirdPatchEvent.upToDate;
      case ShorebirdRunState.error:
        return ShorebirdPatchEvent.error;
    }
  }

  static Future<void> checkAndUpdate() async {
    final result = await checkAndRestartOnLaunch();
    if (result.state == ShorebirdRunState.error) {
      throw result.error ?? StateError('Shorebird update failed');
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    final result = await shorebirdUpdateCoordinator.run();
    final patchNumber = result.currentPatchNumber;
    return patchNumber == null ? null : shorebird.Patch(number: patchNumber);
  }

  static Future<PatchStatusCheckResult> checkPatchStatusForSettings() async {
    if (UniversalPlatform.isWeb) {
      throw const PatchStatusException(PatchStatusError.webUnsupported);
    }

    final result = await shorebirdUpdateCoordinator.run();
    if (result.state == ShorebirdRunState.error) {
      throw PatchStatusException(
        PatchStatusError.generic,
        message: result.error.toString(),
      );
    }

    final status = switch (result.state) {
      ShorebirdRunState.restartRequired =>
        shorebird.UpdateStatus.restartRequired,
      ShorebirdRunState.unavailable => shorebird.UpdateStatus.unavailable,
      _ => shorebird.UpdateStatus.upToDate,
    };

    return PatchStatusCheckResult(
      status: status,
      currentPatchNumber: result.currentPatchNumber,
      nextPatchNumber: result.nextPatchNumber,
    );
  }

  static Future<ShorebirdRunResult> checkAndRestartOnLaunch() async {
    if (UniversalPlatform.isWeb) {
      const result = ShorebirdRunResult.unavailable();
      _onPatchStatusChanged?.call(eventForResult(result));
      return result;
    }

    logger.i('🚀 홈 진입 후 Shorebird 패치 상태 확인');
    _onPatchStatusChanged?.call(ShorebirdPatchEvent.checking);
    final result = await shorebirdUpdateCoordinator.run();
    final event = eventForResult(result);
    _onPatchStatusChanged?.call(event);

    if (result.state == ShorebirdRunState.restartRequired &&
        _downloadCompleteMessage != null) {
      PatchNotificationService.showDownloadCompleteNotification(
        _downloadCompleteMessage!,
      );
    }

    if (result.state == ShorebirdRunState.error) {
      logger.e('Shorebird 패치 확인 실패 (앱은 계속 실행됨)', error: result.error);
    }
    return result;
  }

  static void setDownloadCompleteMessage(String message) {
    _downloadCompleteMessage = message;
  }
}
