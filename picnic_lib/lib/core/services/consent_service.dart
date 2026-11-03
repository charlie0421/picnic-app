import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_machine_budget.dart';

typedef ConsentInfoUpdateRequester =
    void Function(
      ConsentRequestParameters parameters,
      void Function() onSuccess,
      void Function(FormError error) onFailure,
    );

typedef ConsentFormLoader =
    void Function(
      void Function(ConsentForm form) onSuccess,
      void Function(FormError error) onFailure,
    );

/// Narrow adapter around the callback-based UMP API.
///
/// Production and tests use the same orchestration code while platform-channel
/// calls stay at this boundary.
class ConsentSdk {
  const ConsentSdk({
    required this.requestConsentInfoUpdate,
    required this.getConsentStatus,
    required this.isConsentFormAvailable,
    required this.loadConsentForm,
    required this.canRequestAds,
    required this.reset,
    required this.getPrivacyOptionsRequirementStatus,
  });

  factory ConsentSdk.googleMobileAds() {
    return ConsentSdk(
      requestConsentInfoUpdate: (parameters, onSuccess, onFailure) {
        ConsentInformation.instance.requestConsentInfoUpdate(
          parameters,
          onSuccess,
          onFailure,
        );
      },
      getConsentStatus: () => ConsentInformation.instance.getConsentStatus(),
      isConsentFormAvailable: () =>
          ConsentInformation.instance.isConsentFormAvailable(),
      loadConsentForm: ConsentForm.loadConsentForm,
      canRequestAds: () => ConsentInformation.instance.canRequestAds(),
      reset: () => ConsentInformation.instance.reset(),
      getPrivacyOptionsRequirementStatus: () =>
          ConsentInformation.instance.getPrivacyOptionsRequirementStatus(),
    );
  }

  final ConsentInfoUpdateRequester requestConsentInfoUpdate;
  final Future<ConsentStatus> Function() getConsentStatus;
  final Future<bool> Function() isConsentFormAvailable;
  final ConsentFormLoader loadConsentForm;
  final Future<bool> Function() canRequestAds;
  final Future<void> Function() reset;
  final Future<PrivacyOptionsRequirementStatus> Function()
  getPrivacyOptionsRequirementStatus;
}

/// UMP(User Messaging Platform) consent manager.
class ConsentService {
  factory ConsentService() => _instance;

  ConsentService._internal()
    : _sdk = ConsentSdk.googleMobileAds(),
      machineOperationTimeout = const Duration(seconds: 5),
      _machineClock = null;

  ConsentService.withSdk({
    required ConsentSdk sdk,
    this.machineOperationTimeout = const Duration(seconds: 5),
    Duration Function()? machineClock,
  }) : _sdk = sdk,
       _machineClock = machineClock;

  static final ConsentService _instance = ConsentService._internal();

  final ConsentSdk _sdk;
  final Duration machineOperationTimeout;
  final Duration Function()? _machineClock;

  bool _isInitialized = false;
  bool _lastAttemptFailed = false;
  int _generation = 0;
  _ConsentInitializationAttempt? _activeAttempt;
  Future<void>? _resetInFlight;

  /// Checks consent before Mobile Ads initialization.
  ///
  /// All callers share one attempt. Machine-only UMP operations are bounded,
  /// but an already-visible consent form waits for the user's dismissal.
  Future<bool> initialize({StartupMachineBudget? machineOperationBudget}) {
    if (_isInitialized) return Future<bool>.value(true);

    final activeAttempt = _activeAttempt;
    if (activeAttempt != null) return activeAttempt.future;

    final attempt = _ConsentInitializationAttempt(
      _generation,
      machineOperationBudget ?? _newMachineBudget(),
    );
    _activeAttempt = attempt;
    final resetInFlight = _resetInFlight;
    if (resetInFlight == null) {
      unawaited(_runInitialization(attempt));
    } else {
      unawaited(_runInitializationAfterReset(attempt, resetInFlight));
    }
    return attempt.future;
  }

  /// Whether the most recently completed current-generation attempt failed.
  ///
  /// Startup uses this to avoid immediately repeating Group 1 UMP work in
  /// Group 2. Calling [initialize] later still starts a normal retry.
  bool get lastAttemptFailed => _lastAttemptFailed;

  StartupMachineBudget _newMachineBudget() {
    return StartupMachineBudget(
      limit: machineOperationTimeout,
      elapsed: _machineClock,
    );
  }

  Future<void> _runInitializationAfterReset(
    _ConsentInitializationAttempt attempt,
    Future<void> resetFuture,
  ) async {
    await resetFuture;
    if (_isCurrent(attempt)) {
      await _runInitialization(attempt);
    }
  }

  Future<void> _runInitialization(_ConsentInitializationAttempt attempt) async {
    try {
      logger.i('[ConsentService] 동의 정보 확인 시작');

      await _requestConsentInfoUpdate(
        ConsentRequestParameters(),
        attempt.machineOperationBudget,
      );
      if (!_isCurrent(attempt)) return;

      final status = await _awaitMachineOperation(
        _sdk.getConsentStatus,
        budget: attempt.machineOperationBudget,
        stage: 'getConsentStatus',
      );
      if (!_isCurrent(attempt)) return;
      logger.i('[ConsentService] 현재 동의 상태: $status');

      final isFormAvailable = await _awaitMachineOperation(
        _sdk.isConsentFormAvailable,
        budget: attempt.machineOperationBudget,
        stage: 'isConsentFormAvailable',
      );
      if (!_isCurrent(attempt)) return;

      if (isFormAvailable && status == ConsentStatus.required) {
        logger.i('[ConsentService] 동의 폼 표시 필요');
        await _loadAndShowConsentForm(
          attempt: attempt,
          budget: attempt.machineOperationBudget,
        );
      }
      if (!_isCurrent(attempt)) return;

      _isInitialized = true;
      _lastAttemptFailed = false;
      attempt.complete(true);
    } catch (error, stackTrace) {
      logger.e('[ConsentService] 초기화 실패', error: error, stackTrace: stackTrace);
      if (_isCurrent(attempt)) {
        _lastAttemptFailed = true;
      }
      attempt.complete(false);
    } finally {
      if (identical(_activeAttempt, attempt)) {
        _activeAttempt = null;
      }
      attempt.complete(false);
    }
  }

  bool _isCurrent(_ConsentInitializationAttempt attempt) {
    return attempt.generation == _generation &&
        identical(_activeAttempt, attempt) &&
        !attempt.isCompleted;
  }

  Future<T> _awaitMachineOperation<T>(
    Future<T> Function() operation, {
    required StartupMachineBudget budget,
    required String stage,
  }) async {
    return budget.run(operation, stage: '[ConsentService] $stage');
  }

  Future<void> _requestConsentInfoUpdate(
    ConsentRequestParameters parameters,
    StartupMachineBudget budget,
  ) async {
    final completer = Completer<void>();
    var acceptsCallbacks = true;

    void completeSuccess() {
      if (acceptsCallbacks && !completer.isCompleted) {
        completer.complete();
      }
    }

    void completeFailure(Object error, [StackTrace? stackTrace]) {
      if (acceptsCallbacks && !completer.isCompleted) {
        completer.completeError(error, stackTrace ?? StackTrace.current);
      }
    }

    try {
      await _awaitMachineOperation(
        () {
          runZonedGuarded(() {
            _sdk.requestConsentInfoUpdate(
              parameters,
              completeSuccess,
              completeFailure,
            );
          }, completeFailure);
          return completer.future;
        },
        budget: budget,
        stage: 'requestConsentInfoUpdate',
      );
      logger.i('[ConsentService] 동의 정보 업데이트 완료');
    } finally {
      acceptsCallbacks = false;
    }
  }

  Future<void> _loadAndShowConsentForm({
    _ConsentInitializationAttempt? attempt,
    int? standaloneGeneration,
    required StartupMachineBudget budget,
  }) async {
    final generation = standaloneGeneration ?? attempt!.generation;
    final form = await _loadConsentForm(
      attempt: attempt,
      generation: generation,
      budget: budget,
    );

    if (!_isFlowCurrent(attempt, generation)) {
      unawaited(_disposeFormSafely(form));
      throw const _StaleConsentFlow();
    }

    final dismissed = Completer<void>();
    var acceptsCallbacks = true;

    void completeDismissal(FormError? error) {
      if (!acceptsCallbacks || dismissed.isCompleted) return;
      if (error == null) {
        dismissed.complete();
      } else {
        dismissed.completeError(error, StackTrace.current);
      }
    }

    void completeLaunchFailure(Object error, StackTrace stackTrace) {
      if (acceptsCallbacks && !dismissed.isCompleted) {
        dismissed.completeError(error, stackTrace);
      }
    }

    try {
      runZonedGuarded(() {
        form.show(completeDismissal);
      }, completeLaunchFailure);

      // Intentionally no timeout: after presentation this future represents an
      // active user's privacy choice, not a stalled machine operation.
      await dismissed.future;
      logger.i('[ConsentService] 동의 폼 닫힘');
    } finally {
      acceptsCallbacks = false;
      // Native cleanup is observed but cannot hold startup after the user's
      // choice has already been delivered.
      unawaited(_disposeFormSafely(form));
    }
  }

  Future<ConsentForm> _loadConsentForm({
    required _ConsentInitializationAttempt? attempt,
    required int generation,
    required StartupMachineBudget budget,
  }) async {
    final completer = Completer<ConsentForm>();
    var acceptsCallbacks = true;

    void completeSuccess(ConsentForm form) {
      if (!acceptsCallbacks || !_isFlowCurrent(attempt, generation)) {
        unawaited(_disposeFormSafely(form));
        if (acceptsCallbacks && !completer.isCompleted) {
          completer.completeError(
            const _StaleConsentFlow(),
            StackTrace.current,
          );
        }
        return;
      }
      if (!completer.isCompleted) completer.complete(form);
    }

    void completeFailure(Object error, [StackTrace? stackTrace]) {
      if (acceptsCallbacks && !completer.isCompleted) {
        completer.completeError(error, stackTrace ?? StackTrace.current);
      }
    }

    try {
      return await _awaitMachineOperation(
        () {
          runZonedGuarded(() {
            _sdk.loadConsentForm(completeSuccess, completeFailure);
          }, completeFailure);
          return completer.future;
        },
        budget: budget,
        stage: 'loadConsentForm',
      );
    } finally {
      acceptsCallbacks = false;
    }
  }

  bool _isFlowCurrent(_ConsentInitializationAttempt? attempt, int generation) {
    if (generation != _generation) return false;
    return attempt == null || _isCurrent(attempt);
  }

  Future<void> _disposeFormSafely(ConsentForm form) async {
    try {
      await form.dispose();
    } catch (error, stackTrace) {
      logger.e(
        '[ConsentService] 동의 폼 정리 실패',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Whether UMP currently permits an ad request.
  Future<bool> canRequestAds() async {
    final budget = _newMachineBudget();
    try {
      return await _awaitMachineOperation(
        _sdk.canRequestAds,
        budget: budget,
        stage: 'canRequestAds',
      );
    } catch (error, stackTrace) {
      logger.e(
        '[ConsentService] 광고 요청 가능 여부 확인 실패',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<ConsentStatus> getConsentStatus() {
    final budget = _newMachineBudget();
    return _awaitMachineOperation(
      _sdk.getConsentStatus,
      budget: budget,
      stage: 'getConsentStatus',
    );
  }

  Future<bool> isGdprApplicable() async {
    final status = await getConsentStatus();
    return status == ConsentStatus.required || status == ConsentStatus.obtained;
  }

  /// Invalidates the current generation before awaiting the platform reset.
  /// Old callers are always settled as false, even if the platform call stalls.
  Future<void> reset() {
    _generation++;
    _isInitialized = false;
    _lastAttemptFailed = false;

    final oldAttempt = _activeAttempt;
    _activeAttempt = null;
    oldAttempt?.complete(false);

    final resetInFlight = _resetInFlight;
    if (resetInFlight != null) return resetInFlight;

    late final Future<void> resetFuture;
    final budget = _newMachineBudget();
    resetFuture =
        _awaitMachineOperation(_sdk.reset, budget: budget, stage: 'reset')
            .catchError((Object error, StackTrace stackTrace) {
              logger.e(
                '[ConsentService] 동의 상태 초기화 실패',
                error: error,
                stackTrace: stackTrace,
              );
            })
            .whenComplete(() {
              if (identical(_resetInFlight, resetFuture)) {
                _resetInFlight = null;
              }
            });
    _resetInFlight = resetFuture;

    logger.i('[ConsentService] 동의 상태 초기화됨');
    return resetFuture;
  }

  Future<bool> resetAndReinitialize() async {
    logger.i('[ConsentService] 동의 상태 초기화 및 재초기화 시작');
    await reset();
    return initialize();
  }

  Future<void> showPrivacyOptionsForm() async {
    final budget = _newMachineBudget();
    try {
      final generation = _generation;
      final status = await _awaitMachineOperation(
        _sdk.getPrivacyOptionsRequirementStatus,
        budget: budget,
        stage: 'getPrivacyOptionsRequirementStatus',
      );
      if (generation != _generation) return;

      if (status == PrivacyOptionsRequirementStatus.required) {
        await _loadAndShowConsentForm(
          standaloneGeneration: generation,
          budget: budget,
        );
      } else {
        logger.i('[ConsentService] 개인정보 옵션 폼 표시 불필요');
      }
    } catch (error, stackTrace) {
      logger.e(
        '[ConsentService] 개인정보 옵션 폼 표시 실패',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logCurrentState() async {
    final status = await getConsentStatus();
    final canRequest = await canRequestAds();

    logger.i('[ConsentService] === 현재 상태 ===');
    logger.i('[ConsentService] 동의 상태: $status');
    logger.i('[ConsentService] 광고 요청 가능: $canRequest');
    logger.i('[ConsentService] 초기화 완료: $_isInitialized');
    logger.i('[ConsentService] ==================');
  }
}

class _ConsentInitializationAttempt {
  _ConsentInitializationAttempt(this.generation, this.machineOperationBudget);

  final int generation;
  final StartupMachineBudget machineOperationBudget;
  final Completer<bool> _completer = Completer<bool>();

  Future<bool> get future => _completer.future;
  bool get isCompleted => _completer.isCompleted;

  void complete(bool result) {
    if (!_completer.isCompleted) _completer.complete(result);
  }
}

class _StaleConsentFlow implements Exception {
  const _StaleConsentFlow();

  @override
  String toString() => 'Consent flow was superseded';
}
