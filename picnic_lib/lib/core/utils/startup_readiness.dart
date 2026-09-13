import 'dart:async';

typedef AsyncInitializer = Future<void> Function();
typedef AsyncBoolInitializer = Future<bool> Function();
typedef AdMobReadyWaiter = Future<bool> Function({required Duration timeout});

/// Runs named startup work at most once after it succeeds.
///
/// A failed stage may be retried. While a stage is still running every caller
/// receives the same future, including callers that arrive after a separate
/// timeout observer has stopped waiting for it.
class RetryableStartupStages {
  final Set<String> _successful = <String>{};
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  bool isSuccessful(String name) => _successful.contains(name);

  Future<void> run(String name, AsyncInitializer initialize) {
    if (_successful.contains(name)) return Future<void>.value();

    final inFlight = _inFlight[name];
    if (inFlight != null) return inFlight;

    late final Future<void> attempt;
    attempt = Future<void>.sync(initialize)
        .then((_) {
          _successful.add(name);
        })
        .whenComplete(() {
          if (identical(_inFlight[name], attempt)) {
            _inFlight.remove(name);
          }
        });
    _inFlight[name] = attempt;
    return attempt;
  }

  /// Bounds only this caller's wait; [run]'s underlying attempt keeps running.
  Future<void> observe(
    String name,
    AsyncInitializer initialize, {
    required Duration timeout,
  }) => run(name, initialize).timeout(timeout);
}

class StartupReadinessResult {
  const StartupReadinessResult.ready()
    : isReady = true,
      error = null,
      stackTrace = null;

  const StartupReadinessResult.failed(this.error, this.stackTrace)
    : isReady = false;

  final bool isReady;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Converts a retryable startup attempt into an explicit, non-throwing result.
class StartupReadinessController {
  final Completer<StartupReadinessResult> _firstAttempt =
      Completer<StartupReadinessResult>();
  Future<StartupReadinessResult>? _inFlight;
  StartupReadinessResult? _lastResult;

  Future<StartupReadinessResult> get ready {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final lastResult = _lastResult;
    if (lastResult != null) {
      return Future<StartupReadinessResult>.value(lastResult);
    }
    return _firstAttempt.future;
  }

  Future<StartupReadinessResult> run(AsyncInitializer initialize) {
    final lastResult = _lastResult;
    if (lastResult?.isReady == true) {
      return Future<StartupReadinessResult>.value(lastResult);
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    late final Future<StartupReadinessResult> attempt;
    attempt = Future<void>.sync(initialize)
        .then<StartupReadinessResult>(
          (_) => const StartupReadinessResult.ready(),
          onError: (Object error, StackTrace stackTrace) =>
              StartupReadinessResult.failed(error, stackTrace),
        )
        .then((result) {
          _lastResult = result;
          if (!_firstAttempt.isCompleted) {
            _firstAttempt.complete(result);
          }
          return result;
        })
        .whenComplete(() {
          if (identical(_inFlight, attempt)) _inFlight = null;
        });
    _inFlight = attempt;
    return attempt;
  }
}

class StartupConnectionResult<T> {
  const StartupConnectionResult.offline()
    : hasNetwork = false,
      updateInfo = null,
      isBanned = false;

  const StartupConnectionResult.online({
    required this.updateInfo,
    required this.isBanned,
  }) : hasNetwork = true;

  final bool hasNetwork;
  final T? updateInfo;
  final bool isBanned;
}

/// Runs and atomically publishes the required connection-dependent checks.
/// A timed-out read is superseded by the next explicit retry; SDK initialization
/// uses [RetryableStartupStages] instead and keeps its original work alive.
class StartupConnectionChecks<T> {
  Future<StartupConnectionResult<T>>? _rawInFlight;
  Future<StartupConnectionResult<T>>? _observationInFlight;
  int _observationGeneration = 0;

  Future<StartupConnectionResult<T>> run({
    required Future<bool> Function() checkNetwork,
    required Future<T> Function() checkUpdate,
    required Future<bool> Function() checkBan,
    required void Function(StartupConnectionResult<T> result) publish,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final observationInFlight = _observationInFlight;
    if (observationInFlight != null) return observationInFlight;

    var raw = _rawInFlight;
    if (raw == null) {
      late final Future<StartupConnectionResult<T>> rawAttempt;
      rawAttempt =
          Future<StartupConnectionResult<T>>.sync(() async {
            if (!await checkNetwork()) {
              return StartupConnectionResult<T>.offline();
            }

            final results = await Future.wait<Object?>([
              Future<T>.sync(checkUpdate),
              Future<bool>.sync(checkBan),
            ]);
            return StartupConnectionResult<T>.online(
              updateInfo: results[0] as T,
              isBanned: results[1] as bool,
            );
          }).whenComplete(() {
            if (identical(_rawInFlight, rawAttempt)) _rawInFlight = null;
          });
      _rawInFlight = rawAttempt;
      raw = rawAttempt;
    }

    final generation = ++_observationGeneration;
    late final Future<StartupConnectionResult<T>> observation;
    observation = raw
        .timeout(
          timeout,
          onTimeout: () {
            if (identical(_rawInFlight, raw)) _rawInFlight = null;
            throw TimeoutException(
              'Startup connection checks timed out',
              timeout,
            );
          },
        )
        .then((result) {
          if (generation == _observationGeneration) publish(result);
          return result;
        })
        .whenComplete(() {
          if (identical(_observationInFlight, observation)) {
            _observationInFlight = null;
          }
        });
    _observationInFlight = observation;
    return observation;
  }
}

/// Keeps authentication authoritative while bounding only non-auth SDKs.
class BoundedNonAuthStartupGate {
  const BoundedNonAuthStartupGate({
    required this.nonAuthWaitLimit,
    this.onNonAuthError,
    this.onNonAuthTimeout,
  });

  final Duration nonAuthWaitLimit;
  final void Function(Object error, StackTrace stackTrace)? onNonAuthError;
  final void Function(Duration limit)? onNonAuthTimeout;

  Future<void> wait({
    required AsyncInitializer initializeAuth,
    required AsyncInitializer initializeNonAuth,
  }) async {
    final authFuture = Future<void>.sync(initializeAuth);
    final nonAuthFuture = Future<void>.sync(initializeNonAuth);

    // Attach the error observer immediately so a late failure stays handled
    // even after the splash-facing timeout wins.
    final observedNonAuth = nonAuthFuture.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        onNonAuthError?.call(error, stackTrace);
      },
    );

    await authFuture;

    try {
      await observedNonAuth.timeout(nonAuthWaitLimit);
    } on TimeoutException {
      onNonAuthTimeout?.call(nonAuthWaitLimit);
    }
  }
}

/// Retryable, single-flight owner of the real Mobile Ads initialization.
class RetryableAdMobInitializer {
  RetryableAdMobInitializer({required AsyncBoolInitializer initialize})
    : _initialize = initialize;

  final AsyncBoolInitializer _initialize;
  Future<bool>? _inFlight;
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<bool> initialize() {
    if (_isReady) return Future<bool>.value(true);

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    late final Future<bool> attempt;
    attempt = Future<bool>.sync(_initialize)
        .then((ready) {
          if (ready) _isReady = true;
          return ready;
        }, onError: (Object _, StackTrace _) => false)
        .whenComplete(() {
          if (identical(_inFlight, attempt)) _inFlight = null;
        });
    _inFlight = attempt;
    return attempt;
  }

  /// Returns false to this observer on timeout; the raw attempt keeps running.
  Future<bool> waitForReady({required Duration timeout}) async {
    if (_isReady) return true;
    return initialize().timeout(timeout, onTimeout: () => false);
  }
}

/// Applies both readiness and current UMP permission before an ad request.
class AdRequestReadinessGate {
  const AdRequestReadinessGate({
    required this.waitForAdMob,
    required this.canRequestAds,
  });

  final AdMobReadyWaiter waitForAdMob;
  final Future<bool> Function() canRequestAds;

  Future<T> run<T>({
    required Future<T> Function() request,
    bool Function()? isRequestActive,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (timeout <= Duration.zero || isRequestActive?.call() == false) {
      throw const AdsUnavailable('Ad request is no longer active');
    }

    var observing = true;
    Future<void> checkReadiness() async {
      final ready = await waitForAdMob(timeout: timeout);
      if (!ready) throw const AdsUnavailable('AdMob is not ready');
      if (!observing || isRequestActive?.call() == false) {
        throw const AdsUnavailable('Ad request is no longer active');
      }

      // Initialization may itself complete a consent flow. Read permission
      // afterwards so this request uses the resulting decision.
      if (!await canRequestAds()) {
        throw const AdsUnavailable('UMP does not currently permit ad requests');
      }
    }

    try {
      // One deadline covers both sequential checks. Late completion of either
      // check cannot reach the request below after this observer times out.
      await checkReadiness().timeout(timeout);
    } on AdsUnavailable {
      rethrow;
    } catch (error) {
      throw AdsUnavailable('Ad readiness check failed', cause: error);
    } finally {
      observing = false;
    }

    if (isRequestActive?.call() == false) {
      throw const AdsUnavailable('Ad request is no longer active');
    }
    return Future<T>.sync(request);
  }
}

class AdsUnavailable implements Exception {
  const AdsUnavailable(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AdsUnavailable: $message';
}
