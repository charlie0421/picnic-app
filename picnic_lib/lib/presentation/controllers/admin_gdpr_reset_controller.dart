import 'dart:async';

typedef GdprResetCallback = Future<bool> Function();
typedef GdprStateLogCallback = Future<void> Function();

enum AdminGdprResetResult { success, failure, inProgress }

/// Coordinates an administrator-triggered GDPR reset without depending on
/// Flutter or platform channels.
class AdminGdprResetController {
  AdminGdprResetController({
    required GdprResetCallback resetAndReinitialize,
    required GdprStateLogCallback logCurrentState,
  }) : _resetAndReinitialize = resetAndReinitialize,
       _logCurrentState = logCurrentState;

  final GdprResetCallback _resetAndReinitialize;
  final GdprStateLogCallback _logCurrentState;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<AdminGdprResetResult> reset() async {
    if (_isRunning) {
      return AdminGdprResetResult.inProgress;
    }

    _isRunning = true;
    try {
      return await _resetAndReinitialize()
          ? AdminGdprResetResult.success
          : AdminGdprResetResult.failure;
    } catch (_) {
      return AdminGdprResetResult.failure;
    } finally {
      _isRunning = false;
      unawaited(_logStateBestEffort());
    }
  }

  Future<void> _logStateBestEffort() async {
    try {
      await _logCurrentState();
    } catch (_) {
      // State logging must not affect reset or reload behavior.
    }
  }
}
