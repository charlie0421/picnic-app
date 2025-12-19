import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/patch_notification_service.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:universal_platform/universal_platform.dart';

final updater = shorebird.ShorebirdUpdater();
final _localNotifications = FlutterLocalNotificationsPlugin();

/// 패치 대기 상태 (백그라운드 재시작용)
bool _hasPendingPatch = false;

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
  /// 패치 상태 변경 콜백 등록
  /// 앱 초기화 시 호출하여 패치 상태 변경을 감지할 수 있습니다.
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

        // 업데이트 시도 전 상태 확인
        final patchBefore = await updater.readCurrentPatch();
        logger.i('📋 업데이트 전 패치 정보: ${patchBefore?.number}');

        await updater.update();

        // 업데이트 후 상태 확인
        final patchAfter = await updater.readCurrentPatch();
        logger.i('📋 업데이트 후 패치 정보: ${patchAfter?.number}');

        // 패치가 실제로 변경되었는지 확인
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

    try {
      logger.i('🔍 설정 페이지 패치 상태 확인');

      // 현재 실행 중인 패치
      final currentPatch = await updater.readCurrentPatch();

      // 다운로드되어 대기 중인 패치 (다음 재시작 시 적용)
      final nextPatch = await updater.readNextPatch();

      // 서버에서 새 패치 확인 (10초 타임아웃)
      final status = await updater.checkForUpdate().timeout(
        Duration(seconds: 10),
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

  /// 네이티브 앱 재시작 (Shorebird 패치 적용을 위해)
  /// iOS: 로컬 푸시 알림으로 재시작 유도 (Apple 정책상 프로그래밍적 재시작 불가)
  /// Android: restart_app 패키지로 앱 재시작
  static Future<void> restartAppForPatch({
    String? notificationTitle,
    String? notificationBody,
  }) async {
    if (UniversalPlatform.isWeb) {
      logger.w('웹에서는 네이티브 재시작을 지원하지 않습니다');
      return;
    }

    try {
      if (Platform.isIOS) {
        // iOS: 로컬 푸시 알림으로 재시작 유도
        // Apple 정책상 프로그래밍적 재시작 불가능
        logger.i('🔔 iOS - 로컬 푸시 알림으로 재시작 유도');
        await showRestartNotification(
          title: notificationTitle ?? 'Update Ready',
          body: notificationBody ?? 'Please close and reopen the app to apply the update.',
        );
        // iOS에서는 앱을 종료하지 않고 사용자가 수동으로 앱을 재시작하도록 유도
        // exit(0)을 호출하면 App Store 심사에서 리젝될 수 있음
      } else {
        // Android: 직접 재시작
        logger.i('🔄 Android - 네이티브 앱 재시작 실행');
        await Restart.restartApp();
      }
    } catch (e, stackTrace) {
      logger.e('❌ 앱 재시작 처리 실패: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 즉시 로컬 푸시 알림 표시 (재시작 유도용)
  static Future<void> showRestartNotification({
    required String title,
    required String body,
  }) async {
    if (UniversalPlatform.isWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'patch_update_channel',
        'Patch Updates',
        channelDescription: 'Notifications for app patch updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        9999,
        title,
        body,
        notificationDetails,
      );

      logger.i('🔔 재시작 유도 로컬 푸시 알림 표시됨');
    } catch (e, stackTrace) {
      logger.e('❌ 로컬 푸시 알림 표시 실패: $e', stackTrace: stackTrace);
    }
  }

  /// 앱 시작시 패치 체크 (재시작 없이 백그라운드 다운로드)
  ///
  /// 앱 초기화 중에 재시작하면 앱이 행(hang)될 수 있으므로,
  /// 패치 다운로드만 수행하고 앱은 정상 실행됩니다.
  /// 사용자가 설정에서 수동으로 재시작하거나, 앱을 완전히 종료 후
  /// 다시 열면 패치가 적용됩니다.
  static Future<void> checkAndRestartOnLaunch() async {
    if (UniversalPlatform.isWeb) {
      logger.i('웹에서는 Shorebird 패치를 지원하지 않습니다');
      return;
    }

    try {
      logger.i('🚀 앱 시작시 Shorebird 패치 상태 확인');
      _notifyPatchStatus(ShorebirdPatchEvent.checking);

      // 먼저 대기 중인 패치가 있는지 확인
      final status = await updater.checkForUpdate();
      logger.i('📊 Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.restartRequired) {
        // 이미 패치가 다운로드되어 재시작만 필요한 경우
        // 앱 초기화 중에는 재시작하지 않음 (행 방지)
        logger.i('🔄 대기 중인 패치 발견 - 백그라운드 전환 시 자동 적용됨');
        _hasPendingPatch = true;
        _notifyPatchStatus(ShorebirdPatchEvent.restartPending);
        // normal 방식: 로컬 푸시 없이 설정 페이지 배너와 백그라운드 재시작으로 처리
        return;
      }

      if (status == shorebird.UpdateStatus.outdated) {
        // 새 패치가 있는 경우 백그라운드에서 다운로드 (재시작 안 함)
        logger.i('🆕 새 패치 발견 - 백그라운드 다운로드 시작');
        _notifyPatchStatus(ShorebirdPatchEvent.downloading);
        // 비동기로 다운로드 (앱 초기화 blocking 방지)
        _downloadPatchInBackground();
        return;
      }

      logger.i('✅ 패치 없음 또는 최신 상태');
      _notifyPatchStatus(ShorebirdPatchEvent.upToDate);
    } catch (e, stackTrace) {
      logger.e('❌ 앱 시작시 패치 확인 실패 (앱은 계속 실행됨): $e',
          stackTrace: stackTrace);
      _notifyPatchStatus(ShorebirdPatchEvent.error);
      // 패치 확인 실패해도 앱은 계속 실행되도록 함
    }
  }

  /// 백그라운드에서 패치 다운로드 (앱 초기화 blocking 방지)
  static Future<void> _downloadPatchInBackground() async {
    try {
      await updater.update();
      logger.i('✅ 패치 다운로드 완료 - 백그라운드 전환 시 자동 적용됨');
      _hasPendingPatch = true;
      _notifyPatchStatus(ShorebirdPatchEvent.downloadCompleted);

      // 다운로드 완료 스낵바 표시 (중간 수준 알림)
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

  /// 패치 대기 상태 확인
  static bool get hasPendingPatch => _hasPendingPatch;

  /// 패치 대기 상태 설정 (외부에서 설정 필요 시)
  static void setPendingPatch(bool value) {
    _hasPendingPatch = value;
  }

  /// 다운로드 완료 알림 메시지 설정 (L10N 적용용)
  ///
  /// 앱 초기화 시 L10N 문자열로 설정해야 함
  static void setDownloadCompleteMessage(String message) {
    _downloadCompleteMessage = message;
  }
}
