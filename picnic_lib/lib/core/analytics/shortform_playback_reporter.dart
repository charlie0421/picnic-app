import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Best-effort cumulative statements, separate from all reward callbacks.
/// The server stores greatest(existing, statement), so timeout retries are safe.
/// At most one attempt starts per second and three consecutive failures end
/// reporting for this impression. A final close can finish bounded retries.
class ShortformPlaybackReporter {
  ShortformPlaybackReporter({
    required bool Function() eligible,
    required Future<void> Function(int watchedMs) send,
    Duration Function()? elapsed,
  }) : _eligible = eligible,
       _send = send {
    final watch = Stopwatch()..start();
    _elapsed = elapsed ?? (() => watch.elapsed);
  }

  factory ShortformPlaybackReporter.forImpression({
    required String impressionId,
    required String ownerUserId,
    required String? Function() currentOwner,
    required bool Function() hasConsent,
    required Future<void> Function(String name, Map<String, dynamic> params)
    invoke,
  }) {
    final valid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(impressionId);
    return ShortformPlaybackReporter(
      eligible: () =>
          valid &&
          ownerUserId.isNotEmpty &&
          currentOwner() == ownerUserId &&
          hasConsent(),
      send: (ms) => invoke('record_kpop_playback', {
        'p_impression': impressionId,
        'p_watched_ms': ms,
        'p_opt_in': true,
      }),
    );
  }

  final bool Function() _eligible;
  final Future<void> Function(int) _send;
  late final Duration Function() _elapsed;
  Timer? _retry;
  Duration _nextAttempt = Duration.zero;
  int _pending = 0;
  int _acknowledged = 0;
  int _failures = 0;
  bool _sending = false;
  bool _stopped = false;
  bool _closing = false;
  bool _flushAgain = false;

  bool get canMeasure {
    if (_stopped) return false;
    try {
      return _eligible();
    } catch (_) {
      return false;
    }
  }

  void update(int cumulativeMs) {
    if (!_stopped && !_closing) _pending = math.max(_pending, cumulativeMs);
  }

  Future<void> flush() async {
    if (_stopped) return;
    if (!canMeasure) {
      stop();
      return;
    }
    if (_sending) {
      _flushAgain = true;
      return;
    }
    if (_retry != null || _pending <= _acknowledged) return;
    final delay = _nextAttempt - _elapsed();
    if (delay > Duration.zero) {
      _schedule(delay);
      return;
    }
    _sending = true;
    _flushAgain = false;
    final statement = _pending;
    _nextAttempt = _elapsed() + const Duration(seconds: 1);
    var success = false;
    try {
      await Future.sync(
        () => _send(statement),
      ).timeout(const Duration(seconds: 3));
      _acknowledged = math.max(_acknowledged, statement);
      _failures = 0;
      success = true;
    } catch (error) {
      _failures++;
      if (_failures >= 3 || _isMissingApi(error)) {
        stop();
      } else if (canMeasure) {
        _schedule(Duration(seconds: _failures));
      } else {
        stop();
      }
    } finally {
      _sending = false;
    }
    if (success && (_closing || _flushAgain) && _pending > _acknowledged) {
      unawaited(flush());
    }
  }

  static bool _isMissingApi(Object error) =>
      error is PostgrestException &&
      (error.code == '42883' || error.code == 'PGRST202');

  void _schedule(Duration delay) {
    if (_stopped || _retry != null) return;
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(flush());
    });
  }

  Future<void> close() async {
    _closing = true;
    await flush();
  }

  /// Consent revocation and ownership loss discard queued statements.
  void stop() {
    _stopped = true;
    _pending = 0;
    _retry?.cancel();
    _retry = null;
  }
}
