import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';

Future<UpdateInfo?> checkForUpdates(WidgetRef ref) async {
  try {
    final updateInfoState = await ref.read(checkUpdateProvider.future);
    logger.d('업데이트 상태: ${updateInfoState?.status}');
    return updateInfoState;
    // return updateInfoState?.copyWith(
    //   status: UpdateStatus.updateRecommended,
    // );
  } catch (e, s) {
    logger.e('업데이트 확인 중 오류 발생', error: e, stackTrace: s);
    return null;
  }
}
