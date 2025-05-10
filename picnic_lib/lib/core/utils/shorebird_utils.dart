import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'dart:async';

final updater = shorebird.ShorebirdUpdater();

class ShorebirdUtils {
  static Future<void> checkAndUpdate() async {
    try {
      logger.i('Shorebird 업데이트 체크 시작');
      final status = await updater.checkForUpdate();

      if (status == shorebird.UpdateStatus.outdated) {
        logger.i('Shorebird 업데이트 필요 - 업데이트 시작');
        await updater.update();
        logger.i('Shorebird 업데이트 완료');
        
      } else {
        logger.i('Shorebird 최신 버전 유지 중');
      }
    } catch (e) {
      logger.e('Shorebird 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    try {
      final patch = await updater.readCurrentPatch();
      logger.i('코드 푸시 업데이트 상태: ${patch?.number}');
      return patch;
    } catch (e) {
      logger.e('Shorebird 패치 정보 읽기 중 오류 발생: $e');
      return null;
    }
  }
}
