import 'dart:async';

/// A cumulative timeout for sequential startup work that does not count gaps.
///
/// Only time spent inside [run] is charged. User-controlled waits therefore
/// remain unbounded when they are awaited outside this class, while later
/// machine operations resume with the budget that was left before the prompt.
class StartupMachineBudget {
  StartupMachineBudget({
    this.limit = const Duration(seconds: 5),
    Duration Function()? elapsed,
  }) : _elapsed = elapsed ?? _startMonotonicClock();

  final Duration limit;
  final Duration Function() _elapsed;
  Duration _consumed = Duration.zero;

  Duration get remaining {
    final value = limit - _consumed;
    return value > Duration.zero ? value : Duration.zero;
  }

  Future<T> run<T>(
    Future<T> Function() operation, {
    required String stage,
  }) async {
    final available = remaining;
    if (available <= Duration.zero) {
      throw TimeoutException(
        'Startup machine-operation budget exhausted before $stage',
        Duration.zero,
      );
    }

    final startedAt = _elapsed();
    try {
      return await Future<T>.sync(operation).timeout(
        available,
        onTimeout: () => throw TimeoutException(
          'Startup machine-operation budget exhausted during $stage',
          available,
        ),
      );
    } finally {
      final elapsed = _elapsed() - startedAt;
      if (elapsed > Duration.zero) {
        _consumed += elapsed < available ? elapsed : available;
      }
    }
  }

  static Duration Function() _startMonotonicClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}
