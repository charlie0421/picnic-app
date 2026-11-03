import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/utils/admob_test_device_policy.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_machine_budget.dart';
import 'package:picnic_lib/core/utils/ui.dart';

typedef PrivacyConsentErrorHandler =
    void Function(String stage, Object error, StackTrace stackTrace);
typedef UmpInitializer =
    Future<bool> Function(StartupMachineBudget machineOperationBudget);

/// Coordinates platform privacy prompts without initializing or requesting ads.
///
/// ATT is an iOS-only prerequisite. UMP is always attempted, including after
/// ATT refusal or failure, because request configuration is not a substitute
/// for regulatory consent.
class PrivacyConsentFlow {
  const PrivacyConsentFlow({
    required this.isIOS,
    required this.readTrackingStatus,
    required this.waitForAttPresentation,
    required this.requestTrackingAuthorization,
    required this.configureNonPersonalizedAds,
    required this.initializeUmp,
    this.machineOperationTimeout = const Duration(seconds: 5),
    this.machineOperationBudget,
    this.onError,
  });

  final bool isIOS;
  final Future<TrackingStatus> Function() readTrackingStatus;
  final Future<void> Function() waitForAttPresentation;
  final Future<TrackingStatus> Function() requestTrackingAuthorization;
  final Future<void> Function() configureNonPersonalizedAds;
  final UmpInitializer initializeUmp;
  final Duration machineOperationTimeout;
  final StartupMachineBudget? machineOperationBudget;
  final PrivacyConsentErrorHandler? onError;

  Future<void> initialize() async {
    final budget =
        machineOperationBudget ??
        StartupMachineBudget(limit: machineOperationTimeout);
    var attAuthorized = true;
    if (isIOS) {
      attAuthorized = await _requestAttConsent(budget);
      if (!attAuthorized) {
        await _configureNonPersonalizedAds(budget);
      }
    }

    try {
      final initialized = await initializeUmp(budget);
      if (!initialized) {
        _reportError(
          'ump',
          StateError('UMP consent initialization did not complete'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      _reportError('ump', error, stackTrace);
    }
  }

  Future<bool> _requestAttConsent(StartupMachineBudget budget) async {
    try {
      final status = await _awaitMachineOperation(
        readTrackingStatus,
        budget: budget,
        stage: 'att-status',
      );
      if (status != TrackingStatus.notDetermined) {
        return status == TrackingStatus.authorized;
      }

      // This fixed local delay lets iOS present the first prompt. It does not
      // spend the SDK-response budget: a slow successful status read must not
      // cancel a prompt merely because less than one second remains.
      await waitForAttPresentation();

      // Intentionally outside the machine budget: once requested, this Future
      // represents a visible system prompt and must wait for the user's choice.
      final requestedStatus = await requestTrackingAuthorization();
      return requestedStatus == TrackingStatus.authorized;
    } catch (error, stackTrace) {
      _reportError('att', error, stackTrace);
      return false;
    }
  }

  Future<void> _configureNonPersonalizedAds(StartupMachineBudget budget) async {
    try {
      await _awaitMachineOperation(
        configureNonPersonalizedAds,
        budget: budget,
        stage: 'non-personalized-config',
      );
    } catch (error, stackTrace) {
      _reportError('non-personalized-config', error, stackTrace);
    }
  }

  void _reportError(String stage, Object error, StackTrace stackTrace) {
    onError?.call(stage, error, stackTrace);
  }

  Future<T> _awaitMachineOperation<T>(
    Future<T> Function() operation, {
    required StartupMachineBudget budget,
    required String stage,
  }) {
    return budget.run(operation, stage: 'Privacy consent: $stage');
  }
}

class PrivacyConsentManager {
  static Future<void> initialize() async {
    if (!isMobile()) return;

    final machineOperationBudget = StartupMachineBudget();
    final flow = PrivacyConsentFlow(
      isIOS: Platform.isIOS,
      readTrackingStatus: () async {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        logger.i('Initial ATT status: $status');
        return status;
      },
      waitForAttPresentation: () =>
          Future<void>.delayed(const Duration(seconds: 1)),
      requestTrackingAuthorization: () async {
        final status =
            await AppTrackingTransparency.requestTrackingAuthorization();
        logger.i('ATT status after request: $status');
        return status;
      },
      configureNonPersonalizedAds: _configureNonPersonalizedAds,
      initializeUmp: (budget) =>
          ConsentService().initialize(machineOperationBudget: budget),
      machineOperationBudget: machineOperationBudget,
      onError: (stage, error, stackTrace) {
        logger.e(
          'Privacy consent stage failed: $stage',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    await flow.initialize();
    logger.i('Privacy consent initialization completed');
  }

  /// Preserves the existing non-personalized request policy after ATT denial.
  /// Mobile Ads initialization remains exclusively owned by MainInitializer.
  static Future<void> _configureNonPersonalizedAds() async {
    final config = RequestConfiguration(
      tagForChildDirectedTreatment: TagForUnderAgeOfConsent.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      maxAdContentRating: MaxAdContentRating.g,
      testDeviceIds: AdMobTestDevicePolicy.testDeviceIds ?? [],
    );

    await MobileAds.instance.updateRequestConfiguration(config);
  }

  static Future<bool> canShowPersonalizedAds() async {
    if (!isMobile()) return false;

    try {
      final attAuthorized =
          !Platform.isIOS ||
          await AppTrackingTransparency.trackingAuthorizationStatus ==
              TrackingStatus.authorized;
      final umpStatus = await ConsentService().getConsentStatus();

      return attAuthorized &&
          (umpStatus == ConsentStatus.obtained ||
              umpStatus == ConsentStatus.notRequired);
    } catch (error, stackTrace) {
      logger.e(
        'Error checking ads personalization status',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
