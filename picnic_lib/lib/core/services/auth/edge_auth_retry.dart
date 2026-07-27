import 'package:supabase_flutter/supabase_flutter.dart';

enum EdgeAuthRecoveryFailureReason { refreshFailed, retryUnauthorized }

class EdgeAuthRecoveryException implements Exception {
  const EdgeAuthRecoveryException(this.reason, {this.cause});

  final EdgeAuthRecoveryFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'EdgeAuthRecoveryException(${reason.name})';
}

bool isRecoverableEdgeAuthFailure(Object error) {
  return error is FunctionException && error.status == 401;
}

Future<T> invokeWithAuthRecovery<T>({
  required Future<T> Function() invoke,
  required Future<bool> Function() refresh,
  void Function(Object error)? onRetryFailure,
}) async {
  try {
    return await invoke();
  } catch (error) {
    if (!isRecoverableEdgeAuthFailure(error)) {
      rethrow;
    }
  }

  late final bool refreshed;
  try {
    refreshed = await refresh();
  } catch (error) {
    throw EdgeAuthRecoveryException(
      EdgeAuthRecoveryFailureReason.refreshFailed,
      cause: error,
    );
  }
  if (!refreshed) {
    throw const EdgeAuthRecoveryException(
      EdgeAuthRecoveryFailureReason.refreshFailed,
    );
  }

  try {
    return await invoke();
  } catch (error) {
    onRetryFailure?.call(error);
    if (isRecoverableEdgeAuthFailure(error)) {
      throw EdgeAuthRecoveryException(
        EdgeAuthRecoveryFailureReason.retryUnauthorized,
        cause: error,
      );
    }
    rethrow;
  }
}
