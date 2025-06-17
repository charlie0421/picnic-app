import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'dart:async';

final updater = shorebird.ShorebirdUpdater();

class ShorebirdUtils {
  static Future<void> checkAndUpdate() async {
    try {
      logger.i('Shorebird 업데이트 체크 시작');
      final status = await updater.checkForUpdate();
      logger.i('Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.outdated) {
        logger.i('Shorebird 업데이트 필요 - 업데이트 시작');

        // 업데이트 시도 전 상태 확인
        final patchBefore = await updater.readCurrentPatch();
        logger.i('업데이트 전 패치 정보: ${patchBefore?.number}');

        await updater.update();

        // 업데이트 후 상태 확인
        final patchAfter = await updater.readCurrentPatch();
        logger.i('업데이트 후 패치 정보: ${patchAfter?.number}');

        // 패치가 실제로 변경되었는지 확인
        if (patchBefore?.number != patchAfter?.number) {
          logger.i(
              'Shorebird 업데이트 성공적으로 완료 (${patchBefore?.number} → ${patchAfter?.number})');
        } else {
          logger.w('Shorebird 업데이트가 완료되었지만 패치 번호가 변경되지 않음');
        }
      } else {
        logger.i('Shorebird 최신 버전 유지 중 (상태: $status)');
      }
    } catch (e, stackTrace) {
      logger.e('Shorebird 업데이트 중 오류 발생: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    try {
      final patch = await updater.readCurrentPatch();
      logger.i('현재 패치 상태: ${patch?.number ?? "패치 없음"}');
      return patch;
    } catch (e, stackTrace) {
      logger.e('Shorebird 패치 정보 읽기 중 오류 발생: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// 업데이트 상태를 더 자세히 확인하는 메서드
  static Future<Map<String, dynamic>> getDetailedStatus() async {
    try {
      final status = await updater.checkForUpdate();
      final patch = await updater.readCurrentPatch();

      return {
        'updateStatus': status.toString(),
        'currentPatch': patch?.number,
        'isRestartRequired': status == shorebird.UpdateStatus.restartRequired,
        'isOutdated': status == shorebird.UpdateStatus.outdated,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      logger.e('Shorebird 상세 상태 확인 중 오류: $e', stackTrace: stackTrace);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 패치 후 재시작 문제 진단 메서드
  static Future<Map<String, dynamic>> diagnosePatchRestartIssue() async {
    final diagnostics = <String, dynamic>{};

    try {
      // 1. 현재 Shorebird 상태 확인
      final status = await updater.checkForUpdate();
      diagnostics['currentStatus'] = status.toString();

      // 2. 현재 패치 정보
      final patch = await updater.readCurrentPatch();
      diagnostics['currentPatchNumber'] = patch?.number;

      // 3. 재시작이 필요한 상태인지 확인
      diagnostics['needsRestart'] =
          status == shorebird.UpdateStatus.restartRequired;

      // 4. 업데이트가 가능한 상태인지 확인
      diagnostics['hasUpdates'] = status == shorebird.UpdateStatus.outdated;

      // 5. 진단 시점 기록
      diagnostics['diagnosticTime'] = DateTime.now().toIso8601String();

      // 6. 권장 조치 결정
      List<String> recommendations = [];

      if (status == shorebird.UpdateStatus.restartRequired) {
        recommendations.add('앱을 완전히 종료하고 다시 시작하세요');
        recommendations.add('Phoenix.rebirth() 호출을 시도하세요');
      } else if (status == shorebird.UpdateStatus.outdated) {
        recommendations.add('업데이트를 먼저 다운로드하세요');
        recommendations.add('업데이트 후 재시작하세요');
      } else {
        recommendations.add('현재 최신 상태입니다');
      }

      diagnostics['recommendations'] = recommendations;

      logger.i('패치 재시작 진단 완료: $diagnostics');
    } catch (e, stackTrace) {
      logger.e('패치 재시작 진단 중 오류: $e', stackTrace: stackTrace);
      diagnostics['error'] = e.toString();
      diagnostics['errorTime'] = DateTime.now().toIso8601String();
    }

    return diagnostics;
  }

  /// 강제 재시작 상태 확인 및 실행
  static Future<bool> forceCheckAndRestart() async {
    try {
      logger.i('강제 재시작 체크 시작');

      final diagnostics = await diagnosePatchRestartIssue();
      logger.i('진단 결과: $diagnostics');

      if (diagnostics['needsRestart'] == true) {
        logger.w('재시작이 필요한 상태가 감지됨');
        return true; // 호출자에게 재시작이 필요함을 알림
      }

      if (diagnostics['hasUpdates'] == true) {
        logger.i('업데이트 후 재시작 필요');
        await checkAndUpdate();
        return true; // 업데이트 후 재시작 필요
      }

      logger.i('재시작이 필요하지 않음');
      return false;
    } catch (e, stackTrace) {
      logger.e('강제 재시작 체크 중 오류: $e', stackTrace: stackTrace);
      return false;
    }
  }
}
