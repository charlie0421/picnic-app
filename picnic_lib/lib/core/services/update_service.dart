import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

typedef StoreUpdateCheck = Future<UpdateInfo?> Function();

Future<UpdateInfo?> checkForUpdates(
  WidgetRef? ref, {
  StoreUpdateCheck? storeUpdateCheck,
}) async {
  try {
    final updateInfoState =
        await (storeUpdateCheck ??
            () => ref!.read(checkUpdateProvider.future))();
    logger.d('업데이트 상태: ${updateInfoState?.status}');
    return updateInfoState;
  } catch (e, s) {
    logger.e('업데이트 확인 중 오류 발생', error: e, stackTrace: s);
    return null;
  }
}
