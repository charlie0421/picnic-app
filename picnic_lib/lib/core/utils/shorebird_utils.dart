import 'dart:async';

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:universal_platform/universal_platform.dart';

final updater = shorebird.ShorebirdUpdater();

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
  /// iOS/Android에서 앱 프로세스를 완전히 재시작합니다.
  static Future<void> restartAppForPatch() async {
    if (UniversalPlatform.isWeb) {
      logger.w('웹에서는 네이티브 재시작을 지원하지 않습니다');
      return;
    }

    try {
      logger.i('🔄 패치 적용을 위한 네이티브 앱 재시작 시작');
      await Restart.restartApp();
    } catch (e, stackTrace) {
      logger.e('❌ 네이티브 앱 재시작 실패: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 앱 시작시 패치 체크 및 자동 재시작
  /// 패치가 다운로드되어 대기 중이면 자동으로 앱을 재시작합니다.
  static Future<void> checkAndRestartOnLaunch() async {
    if (UniversalPlatform.isWeb) {
      logger.i('웹에서는 Shorebird 패치를 지원하지 않습니다');
      return;
    }

    try {
      logger.i('🚀 앱 시작시 Shorebird 패치 상태 확인');

      // 먼저 대기 중인 패치가 있는지 확인
      final status = await updater.checkForUpdate();
      logger.i('📊 Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.restartRequired) {
        // 이미 패치가 다운로드되어 재시작만 필요한 경우
        logger.i('🔄 대기 중인 패치 발견 - 자동 재시작 실행');
        await Future.delayed(const Duration(milliseconds: 500));
        await restartAppForPatch();
        return;
      }

      if (status == shorebird.UpdateStatus.outdated) {
        // 새 패치가 있는 경우 다운로드 후 재시작
        logger.i('🆕 새 패치 발견 - 다운로드 시작');
        await updater.update();
        logger.i('✅ 패치 다운로드 완료 - 자동 재시작 실행');
        await Future.delayed(const Duration(milliseconds: 500));
        await restartAppForPatch();
        return;
      }

      logger.i('✅ 패치 없음 또는 최신 상태');
    } catch (e, stackTrace) {
      logger.e('❌ 앱 시작시 패치 확인 실패 (앱은 계속 실행됨): $e',
          stackTrace: stackTrace);
      // 패치 확인 실패해도 앱은 계속 실행되도록 함
    }
  }
}
