import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

class StartupUpdateCheckException implements Exception {
  const StartupUpdateCheckException(this.message);

  final String message;

  @override
  String toString() => 'StartupUpdateCheckException: $message';
}

/// Owns the authentic provider read while callers observe it with a deadline.
///
/// Concurrent callers share a read. After its deadline the next explicit retry
/// can start a fresh read, so a stalled connection cannot pin every retry.
class ServerUpdateCheckCoordinator {
  Future<UpdateInfo?>? _inFlight;

  Future<UpdateInfo> check({
    required Future<UpdateInfo?> Function() readServer,
    required void Function() invalidate,
    required Duration timeout,
    bool forceRefresh = false,
  }) {
    var raw = _inFlight;
    if (raw == null) {
      if (forceRefresh) invalidate();

      late final Future<UpdateInfo?> attempt;
      attempt = Future<UpdateInfo?>.sync(readServer).whenComplete(() {
        if (identical(_inFlight, attempt)) _inFlight = null;
      });
      _inFlight = attempt;
      raw = attempt;
    }

    return raw
        .timeout(
          timeout,
          onTimeout: () {
            if (identical(_inFlight, raw)) _inFlight = null;
            throw TimeoutException('Server update check timed out', timeout);
          },
        )
        .then((updateInfo) {
          if (updateInfo == null) {
            throw const StartupUpdateCheckException(
              'The mandatory server update check returned no result',
            );
          }
          return updateInfo;
        });
  }
}

final ServerUpdateCheckCoordinator _serverUpdateCheck =
    ServerUpdateCheckCoordinator();

/// Reads the mandatory server update policy.
///
/// Shorebird OTA is intentionally not part of this path. The independent
/// `PatchRestartDialogListener` owns OTA checks and cannot bypass the server's
/// force/recommended update policy.
Future<UpdateInfo> checkForUpdates(
  WidgetRef ref, {
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    return await _serverUpdateCheck.check(
      forceRefresh: forceRefresh,
      timeout: timeout,
      invalidate: () => ref.invalidate(checkUpdateProvider),
      readServer: () => ref.read(checkUpdateProvider.future),
    );
  } catch (error, stackTrace) {
    logger.e('서버 업데이트 확인 중 오류 발생', error: error, stackTrace: stackTrace);
    rethrow;
  }
}
