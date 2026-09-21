import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/core/services/purchase_failure_classifier.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, FunctionException;

/// Where in the money path a purchase failed.
enum PurchaseFailureStage {
  /// The store itself reported the purchase as failed (`PurchaseStatus.error`).
  storeError,

  /// The purchase flow could not be launched.
  initiation,

  /// The server did not confirm settlement of a live purchase.
  settlement,

  /// The server knows the receipt but has not confirmed the grant.
  unconfirmedDuplicate,

  /// The recovery sweep could not settle an unfinished transaction.
  sweepVerification,
}

/// Purchase failure reports for Sentry, and the account they belong to.
///
/// PICNIC-2743: seven users had only rejections and no grant, and Sentry could
/// not tell us anything about them - the scope carried no account id and the
/// purchase path reported nothing. This is the smallest thing that closes that
/// gap without turning Sentry into a copy of the payment evidence:
///
/// - **Only codes leave the device.** A failure is reduced to a code derived
///   from its *type* and status (`http_422:APPLE_JWS_INVALID`, `timeout`,
///   `type:StateError`). The exception object is never attached, because its
///   `toString()` can carry a receipt, a JWS, a token or an email - and so can
///   a server error body, which is why a server code is kept only when it has
///   the shape of a code.
/// - **No breadcrumbs.** Breadcrumbs collect log output, and the app logs
///   things like access tokens; a purchase report is sent from a scope with
///   them cleared.
/// - **The account is the purchasing account.** The id is taken by the caller
///   when the attempt starts and pinned on the event, so a logout or account
///   switch while verification is in flight cannot move the report to someone
///   else. With no account, the event carries none rather than inheriting
///   whatever the scope holds.
/// - **Cancellation is not a failure** and is not reported.
/// - **Reporting never blocks or throws** into the purchase path.
class PurchaseDiagnostics {
  const PurchaseDiagnostics._();

  static final RegExp _serverCode = RegExp(r'^[A-Z][A-Z0-9_]{1,63}$');
  static final RegExp _storeCode = RegExp(r'^[A-Za-z0-9_.\-]{1,64}$');

  /// Binds the signed-in account id (and nothing else) to the Sentry scope.
  ///
  /// `null` clears it - on logout the next account must not inherit it.
  static Future<void> bindUser(String? userId) async {
    try {
      await Sentry.configureScope(
        (scope) => scope.setUser(userId == null ? null : SentryUser(id: userId)),
      );
    } catch (e) {
      logger.w('Sentry 사용자 바인딩 실패(무시): ${e.runtimeType}');
    }
  }

  /// [bindUser] for one auth event, called synchronously in event order so a
  /// quick sign-out/sign-in cannot leave the previous account bound.
  static Future<void> bindUserFromAuthState(AuthState state) =>
      bindUser(state.session?.user.id);

  /// Reports one purchase failure. Fire-and-forget.
  static void reportFailure({
    required PurchaseFailureStage stage,
    required String productId,
    required String? userId,
    Object? error,
    String? storeErrorCode,
  }) {
    try {
      if (_isCancellation(storeErrorCode)) return;

      final code = storeErrorCode != null
          ? _sanitizeStoreCode(storeErrorCode)
          : failureCode(error);
      final failureClass = error == null
          ? PurchaseFailureClass.unknown
          : PurchaseFailureClassifier.classify(error);
      final user = userId == null ? null : SentryUser(id: userId);

      final event = SentryEvent(
        level: SentryLevel.warning,
        logger: 'purchase',
        message: SentryMessage('purchase failure: ${stage.name}'),
        user: user,
        fingerprint: ['purchase-failure', stage.name, code],
        tags: {
          'purchase.stage': stage.name,
          'purchase.code': code,
          'purchase.failure_class': failureClass.name,
          'purchase.product_id': productId,
          'purchase.platform': defaultTargetPlatform.name,
        },
      );

      unawaited(
        Sentry.captureEvent(
          event,
          hint: Hint.withMap({_hintKey: _PurchaseReportMarker(userId)}),
          withScope: (scope) async {
            scope.clearBreadcrumbs();
            await scope.setUser(user);
          },
        ).then<void>((_) {}, onError: (Object e) {
          logger.w('구매 실패 Sentry 보고 실패(무시): ${e.runtimeType}');
        }),
      );
    } catch (e) {
      logger.w('구매 실패 Sentry 보고 실패(무시): ${e.runtimeType}');
    }
  }

  static const String _hintKey = 'picnic.purchase_diagnostics';

  /// Re-applies the diagnostics contract to a purchase report **after**
  /// native enrichment. Called from `beforeSend`; every other event is
  /// returned untouched.
  ///
  /// The cloned scope in [reportFailure] is not enough on iOS/Android:
  /// `LoadContextsIntegration` runs after the scope and fills a null
  /// `event.user` from the native scope (iOS substitutes the installation id,
  /// or the account bound before a switch) and replaces the breadcrumbs with
  /// the native trail. So the report carries its owner in the capture's own
  /// [Hint] - fixed when the report was made, never read back from the
  /// (enriched) event or the current global user - and this puts it back.
  static SentryEvent sanitizeForSend(SentryEvent event, Hint hint) {
    final marker = hint.get(_hintKey);
    if (marker is! _PurchaseReportMarker) return event;
    final userId = marker.userId;
    return event
      ..breadcrumbs = const []
      ..user = userId == null ? null : SentryUser(id: userId);
  }

  /// A code for [error] built from its type and status only.
  @visibleForTesting
  static String failureCode(Object? error) {
    if (error == null) return 'unknown';
    if (error is FunctionException) {
      final serverCode = _serverErrorCode(error.details);
      return serverCode == null
          ? 'http_${error.status}'
          : 'http_${error.status}:$serverCode';
    }
    if (error is ReusedPurchaseException) {
      return error.grantConfirmed ? 'reused_granted' : 'reused_unconfirmed';
    }
    if (error is EdgeAuthRecoveryException) {
      return 'auth_recovery_${error.reason.name}';
    }
    if (error is ReceiptResponseContractException) return 'response_contract';
    if (error is TimeoutException) return 'timeout';
    if (error is SocketException ||
        error is HttpException ||
        error is http.ClientException) {
      return 'network';
    }
    // PurchaseService._validateUserAuthentication 이 던지는 형태. 원문은
    // 보내지 않고 알려진 표식인지 비교만 한다.
    if (error.toString() == 'Exception: USER_NOT_AUTHENTICATED') {
      return 'not_authenticated';
    }
    return 'type:${error.runtimeType}';
  }

  static String? _serverErrorCode(Object? details) {
    Object? raw = details;
    if (raw is Map) {
      raw = raw['error'] ?? raw['code'];
      if (raw is Map) raw = raw['code'];
    }
    if (raw is String && _serverCode.hasMatch(raw)) return raw;
    return null;
  }

  static String _sanitizeStoreCode(String code) =>
      _storeCode.hasMatch(code) ? code : 'unrecognized';

  static bool _isCancellation(String? storeErrorCode) {
    if (storeErrorCode == null) return false;
    final lower = storeErrorCode.toLowerCase();
    return lower.contains('cancel');
  }
}

/// Identifies a purchase report inside `beforeSend` and carries the account
/// it belongs to, fixed at capture time.
@immutable
class _PurchaseReportMarker {
  const _PurchaseReportMarker(this.userId);

  final String? userId;
}
