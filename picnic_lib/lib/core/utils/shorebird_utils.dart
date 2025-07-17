import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'dart:async';
import 'package:universal_platform/universal_platform.dart';

final updater = shorebird.ShorebirdUpdater();

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
              '✅ Shorebird 업데이트 성공적으로 완료 (${patchBefore?.number} → ${patchAfter?.number})');
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
  static Future<String> checkPatchStatusForSettings() async {
    try {
      if (UniversalPlatform.isWeb) {
        return '웹 환경에서는 패치 기능을 사용할 수 없습니다.';
      }

      logger.i('🔍 설정 페이지 패치 상태 확인');

      // 현재 패치 정보 확인
      final currentPatch = await updater.readCurrentPatch();
      final currentPatchNumber = currentPatch?.number;

      logger.i('📋 현재 패치: ${currentPatchNumber ?? "없음"}');

      // 서버에서 새 패치 확인 (10초 타임아웃)
      final status = await updater.checkForUpdate().timeout(
            Duration(seconds: 10),
            onTimeout: () => shorebird.UpdateStatus.unavailable,
          );

      switch (status) {
        case shorebird.UpdateStatus.upToDate:
          return currentPatchNumber != null
              ? 'Patch $currentPatchNumber (최신)'
              : '최신 버전 (패치 없음)';

        case shorebird.UpdateStatus.outdated:
          return currentPatchNumber != null
              ? 'Patch $currentPatchNumber (업데이트 가능)'
              : '새 패치 사용 가능';

        case shorebird.UpdateStatus.unavailable:
          return currentPatchNumber != null
              ? 'Patch $currentPatchNumber (오프라인)'
              : '패치 확인 불가';

        default:
          return currentPatchNumber != null
              ? 'Patch $currentPatchNumber (상태 불명)'
              : '패치 상태 불명';
      }
    } catch (e) {
      logger.e('❌ 설정 페이지 패치 상태 확인 실패: $e');
      return '패치 상태 확인 실패';
    }
  }
}
