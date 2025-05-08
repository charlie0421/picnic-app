import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

Future<UpdateInfo?> checkForUpdates(WidgetRef ref) async {
  try {
    // 1. Shorebird 패치 확인
    final shorebirdUpdater = shorebird.ShorebirdUpdater();
    shorebird.UpdateStatus updateStatus =
        await shorebirdUpdater.checkForUpdate();

    logger.d('Shorebird 패치 상태: $updateStatus');

    if (updateStatus == shorebird.UpdateStatus.outdated) {
      // 패치 다운로드

      logger.d('Shorebird 패치 설치 준비 완료');
      return UpdateInfo(
        status: UpdateStatus.needPatch,
        currentVersion: await _getCurrentPatchInfo(),
        latestVersion: '패치 설치 필요',
        url: null,
        forceVersion: '',
      );
    }

    // 2-4. 서버 업데이트 확인 (권장/강제/최신 버전)
    final updateInfoState = await ref.read(checkUpdateProvider.future);
    logger.d('업데이트 상태: ${updateInfoState?.status}');

    // 이미 서버에서 확인된 상태이므로 그대로 반환
    return updateInfoState;
  } catch (e, s) {
    logger.e('업데이트 확인 중 오류 발생', error: e, stackTrace: s);
    return null;
  }
}

Future<String> _getCurrentPatchInfo() async {
  try {
    final shorebirdUpdater = shorebird.ShorebirdUpdater();
    final patchNumber = await shorebirdUpdater.readCurrentPatch();
    return patchNumber != null ? "$patchNumber" : "패치 없음";
  } catch (e) {
    return "패치 정보 확인 실패";
  }
}
