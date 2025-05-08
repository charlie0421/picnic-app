import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

final updater = shorebird.ShorebirdUpdater();

class ShorebirdUtils {
  static Future<void> checkAndUpdate() async {
    final status = await updater.checkForUpdate();
    if (status == shorebird.UpdateStatus.outdated) {
      await updater.update();
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    final patch = await updater.readCurrentPatch();
    logger.i('코드 푸시 업데이트 상태: ${patch?.number}');

    return patch;
  }
}
