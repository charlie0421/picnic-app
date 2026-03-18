import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/patch_notification_service.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:universal_platform/universal_platform.dart';

final updater = shorebird.ShorebirdUpdater();

/// 다운로드 완료 알림 메시지 (L10N 적용용)
String? _downloadCompleteMessage;

/// 패치 상태 변경 콜백 타입
typedef PatchStatusCallback = void Function(ShorebirdPatchEvent event);

/// 패치 이벤트 타입
enum ShorebirdPatchEvent {
  /// 패치 체크 시작
  checking,

  /// 패치 다운로드 시작
  downloading,

  /// 패치 다운로드 완료 (재시작 필요)
  downloadCompleted,

  /// 이미 재시작 대기 중
  restartPending,

  /// 최신 상태
  upToDate,

  /// 에러 발생
  error,
}

/// 전역 패치 상태 콜백 (앱에서 설정)
PatchStatusCallback? _onPatchStatusChanged;

class PatchStatusCheckResult {
  final shorebird.UpdateStatus status;
  final int? currentPatchNumber;
  final int? nextPatchNumber; // 다운로드되어 대기 중인 패치 (재시작 시 적용)

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
  /// Shorebird 패치 사용 가능 여부 확인
  static Future<bool> isPatchingAvailable() async {
    if (UniversalPlatform.isWeb) {
      return false;
    }
    return true;
  }

  /// 패치 상태 변경 콜백 등록
  static void setOnPatchStatusChanged(PatchStatusCallback? callback) {
    _onPatchStatusChanged = callback;
  }

  /// 패치 상태 변경 알림
  static void _notifyPatchStatus(ShorebirdPatchEvent event) {
    _onPatchStatusChanged?.call(event);
  }

  static Future<void> checkAndUpdate() async {
    try {
      logger.i('🔄 Shorebird 업데이트 체크 시작');
      final status = await updater.checkForUpdate();
      logger.i('📊 Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.outdated) {
        logger.i('🆕 Shorebird 업데이트 필요 - 업데이트 시작');

        final patchBefore = await updater.readCurrentPatch();
        logger.i('📋 업데이트 전 패치 정보: ${patchBefore?.number}');

        await updater.update();

        final patchAfter = await updater.readCurrentPatch();
        logger.i('📋 업데이트 후 패치 정보: ${patchAfter?.number}');

        if (patchBefore?.number != patchAfter?.number) {
          logger.i(
            '✅ Shorebird 업데이트 성공적으로 완료 (${patchBefore?.number} → ${patchAfter?.number})',
          );
        } else {
          logger.w('⚠️ Shorebird 업데이트가 완료되었지만 패치 번호가 변경되지 않음');
        }
      } else {
        logger.i('✅ Shorebird 최신 버전 유지 중 (상태: $status)');
      }
    } catch (e, stackTrace) {
      logger.e('❌ Shorebird 업데이트 중 오류 발생: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    try {
      final patch = await updater.readCurrentPatch();
      logger.i('📋 현재 패치 상태: ${patch?.number ?? "패치 없음"}');
      return patch;
    } catch (e, stackTrace) {
      logger.e('❌ Shorebird 패치 정보 읽기 중 오류 발생: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// 간단한 패치 상태 확인 (설정 페이지용)
  static Future<PatchStatusCheckResult> checkPatchStatusForSettings() async {
    if (UniversalPlatform.isWeb) {
      throw const PatchStatusException(PatchStatusError.webUnsupported);
    }

    if (!await isPatchingAvailable()) {
      logger.i('패치 기능 사용 불가 (웹 환경)');
      return const PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
      );
    }

    try {
      logger.i('🔍 설정 페이지 패치 상태 확인');

      final currentPatch = await updater.readCurrentPatch();
      final nextPatch = await updater.readNextPatch();

      final status = await updater.checkForUpdate().timeout(
        const Duration(seconds: 10),
        onTimeout: () => shorebird.UpdateStatus.unavailable,
      );

      logger.i('📋 현재 패치: ${currentPatch?.number ?? "없음"}, '
          '대기 패치: ${nextPatch?.number ?? "없음"}, 상태: $status');

      return PatchStatusCheckResult(
        status: status,
        currentPatchNumber: currentPatch?.number,
        nextPatchNumber: nextPatch?.number,
      );
    } catch (e, stackTrace) {
      logger.e('❌ 설정 페이지 패치 상태 확인 실패: $e', stackTrace: stackTrace);
      throw PatchStatusException(
        PatchStatusError.generic,
        message: e.toString(),
      );
    }
  }

  /// 앱 시작시 패치 체크 (재시작 없이 백그라운드 다운로드)
  static Future<void> checkAndRestartOnLaunch() async {
    if (UniversalPlatform.isWeb) {
      logger.i('웹에서는 Shorebird 패치를 지원하지 않습니다');
      return;
    }

    if (!await isPatchingAvailable()) {
      logger.i('패치 기능 사용 불가');
      _notifyPatchStatus(ShorebirdPatchEvent.upToDate);
      return;
    }

    try {
      logger.i('🚀 앱 시작시 Shorebird 패치 상태 확인');
      _notifyPatchStatus(ShorebirdPatchEvent.checking);

      final status = await updater.checkForUpdate();
      logger.i('📊 Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.restartRequired) {
        logger.i('🔄 대기 중인 패치 발견 - 백그라운드 전환 시 자동 적용됨');
        _notifyPatchStatus(ShorebirdPatchEvent.restartPending);
        return;
      }

      if (status == shorebird.UpdateStatus.outdated) {
        logger.i('🆕 새 패치 발견 - 백그라운드 다운로드 시작');
        _notifyPatchStatus(ShorebirdPatchEvent.downloading);
        _downloadPatchInBackground();
        return;
      }

      logger.i('✅ 패치 없음 또는 최신 상태');
      _notifyPatchStatus(ShorebirdPatchEvent.upToDate);
    } catch (e, stackTrace) {
      logger.e('❌ 앱 시작시 패치 확인 실패 (앱은 계속 실행됨): $e',
          stackTrace: stackTrace);
      _notifyPatchStatus(ShorebirdPatchEvent.error);
    }
  }

  /// 백그라운드에서 패치 다운로드 (앱 초기화 blocking 방지)
  static Future<void> _downloadPatchInBackground() async {
    try {
      await updater.update();
      logger.i('✅ 패치 다운로드 완료 - 백그라운드 전환 시 자동 적용됨');
      _notifyPatchStatus(ShorebirdPatchEvent.downloadCompleted);

      if (_downloadCompleteMessage != null) {
        PatchNotificationService.showDownloadCompleteNotification(
          _downloadCompleteMessage!,
        );
      }
    } catch (e, stackTrace) {
      logger.e('❌ 백그라운드 패치 다운로드 실패: $e', stackTrace: stackTrace);
      _notifyPatchStatus(ShorebirdPatchEvent.error);
    }
  }

  /// 다운로드 완료 알림 메시지 설정 (L10N 적용용)
  static void setDownloadCompleteMessage(String message) {
    _downloadCompleteMessage = message;
  }
}
