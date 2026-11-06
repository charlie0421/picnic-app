import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The step of the Tapjoy offerwall flow that failed.
enum TapjoyFailureStage {
  /// `Tapjoy.setUserID` and the guards before it.
  setUserId,

  /// `TJPlacement.requestContent` reported `onRequestFailure`.
  placementRequest,

  /// `TJPlacement.getPlacement` gave no placement.
  placementCreate,
}

/// Why the stage failed.
enum TapjoyFailureKind {
  /// No signed-in user.
  noUser,

  /// A `setUserID` attempt is still waiting for its result.
  busy,

  /// A `setUserID` attempt for another account has no result yet.
  otherAccountPending,

  /// No `setUserID` result in the time limit.
  timeout,

  /// The SDK reported a failure.
  sdkFailure,

  /// The platform channel call itself failed.
  channelFailure,

  /// The plugin gave no placement object.
  missingPlacement,
}

/// One Tapjoy failure, classified into closed values for Sentry.
///
/// The plugin passes only a message string for the setUserID and placement
/// failures (Android `TJError.message`, iOS `localizedDescription`) and drops
/// the SDK error code. The message is not a closed value: it can be
/// localized, and its content is not under the app's control. So a report
/// keeps only whether a message was present, never its text.
class TapjoyFailure {
  const TapjoyFailure({
    required this.stage,
    required this.kind,
    this.sdkMessage = 'none',
    this.code,
    this.network = 'unknown',
    this.stackTrace,
  });

  factory TapjoyFailure.classify({
    required TapjoyFailureStage stage,
    required TapjoyFailureKind kind,
    Object? sdkError,
    List<ConnectivityResult>? connectivity,
    StackTrace? stackTrace,
  }) => TapjoyFailure(
    stage: stage,
    kind: kind,
    sdkMessage: describeSdkMessage(sdkError),
    code: describeCode(sdkError),
    network: AdShortformLoadFailure.describeNetwork(connectivity),
    stackTrace: stackTrace,
  );

  final TapjoyFailureStage stage;
  final TapjoyFailureKind kind;

  /// `none` (no SDK message), `empty` or `present`.
  final String sdkMessage;

  /// `platform:<code>` or `missing_plugin` for a channel failure, else null.
  final String? code;

  /// `wifi`, `mobile`, `ethernet`, `vpn`, `none` or `unknown`.
  final String network;
  final StackTrace? stackTrace;

  /// Whether the same user can try again: `yes`, `no` or `unknown`.
  ///
  /// `timeout` and `busy` are `yes` because the setUserID guard allows a
  /// retry for the same account. `noUser` needs a sign-in, and
  /// `otherAccountPending` waits for the earlier account's result.
  String get retryable => switch (kind) {
    TapjoyFailureKind.timeout || TapjoyFailureKind.busy => 'yes',
    TapjoyFailureKind.noUser || TapjoyFailureKind.otherAccountPending => 'no',
    TapjoyFailureKind.sdkFailure ||
    TapjoyFailureKind.channelFailure ||
    TapjoyFailureKind.missingPlacement => 'unknown',
  };

  /// A copy with the network type found after the failure.
  TapjoyFailure withConnectivity(List<ConnectivityResult>? connectivity) =>
      TapjoyFailure(
        stage: stage,
        kind: kind,
        sdkMessage: sdkMessage,
        code: code,
        network: AdShortformLoadFailure.describeNetwork(connectivity),
        stackTrace: stackTrace,
      );

  /// The exception sent to Sentry instead of the SDK text.
  TapjoyFailureException toSentryException() =>
      TapjoyFailureException(stage: stage, kind: kind);

  Map<String, String> get tags => {
    'platform': 'Tapjoy',
    'tapjoy_stage': stage.name,
    'tapjoy_kind': kind.name,
    'tapjoy_sdk_message': sdkMessage,
    'tapjoy_retryable': retryable,
    'network': network,
    'tapjoy_code': ?code,
  };

  List<String> get fingerprint => ['tapjoy-failure', stage.name, kind.name];

  /// A channel error code is allowed in this form only. Other values, such
  /// as a URL, become `invalid`.
  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_.\-]{1,64}$');

  static String describeSdkMessage(Object? sdkError) => switch (sdkError) {
    null => 'none',
    String() => sdkError.trim().isEmpty ? 'empty' : 'present',
    _ => 'none',
  };

  static String? describeCode(Object? sdkError) => switch (sdkError) {
    MissingPluginException() => 'missing_plugin',
    PlatformException(:final code) =>
      'platform:${_codePattern.hasMatch(code) ? code : 'invalid'}',
    _ => null,
  };
}

/// The exception that a Tapjoy report sends. Its text holds only the stage
/// and the kind, so it is safe as a Sentry issue title.
class TapjoyFailureException implements Exception {
  const TapjoyFailureException({required this.stage, required this.kind});

  final TapjoyFailureStage stage;
  final TapjoyFailureKind kind;

  @override
  String toString() => 'TapjoyFailure(stage=${stage.name}, kind=${kind.name})';
}

/// Sends [failure] to Sentry with the current network type.
///
/// Called with `unawaited` next to the failure dialog, so it never throws:
/// a failed network lookup gives `unknown`, and a failed send is ignored.
/// [checkConnectivity] and [send] are test seams.
Future<void> sendTapjoyFailureReport(
  TapjoyFailure failure, {
  Future<List<ConnectivityResult>> Function()? checkConnectivity,
  Future<void> Function(TapjoyFailure failure)? send,
}) async {
  List<ConnectivityResult>? connectivity;
  try {
    connectivity = await (checkConnectivity ?? Connectivity().checkConnectivity)
        .call();
  } catch (_) {
    connectivity = null;
  }
  try {
    await (send ?? _sendToSentry)(failure.withConnectivity(connectivity));
  } catch (_) {
    // A report must not break the offerwall flow.
  }
}

Future<void> _sendToSentry(TapjoyFailure failure) async {
  await Sentry.captureException(
    failure.toSentryException(),
    stackTrace: failure.stackTrace,
    withScope: (scope) {
      failure.tags.forEach(scope.setTag);
      scope.fingerprint = failure.fingerprint;
    },
  );
}
