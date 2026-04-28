import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Detects the Supabase Edge Function `ACCOUNT_DELETED` signal and triggers
/// a one-shot local sign-out so the client stops issuing repeated 403s for
/// a soft-deleted account.
///
/// Background:
/// - When `users.deleted_at` is non-null, every Edge Function (attendance,
///   user-info, push-token, receipts, ...) returns:
///     `FunctionException(status: 403,
///                        details: {success: false,
///                                  error: {code: ACCOUNT_DELETED,
///                                          message: "Account deleted"}},
///                        reasonPhrase: Forbidden)`
/// - Without intervention each provider catch-block reports the error to
///   Sentry. A single deleted-account user generates many noise events
///   per session (PICNIC-APP-4ZY etc.) and continues to do so on every app
///   launch because the local Supabase session is still valid.
/// - This handler signs the user out the moment the first ACCOUNT_DELETED
///   reaches Sentry's `beforeSend`, so subsequent provider rebuilds short-
///   circuit (e.g. `Attendance.build` returns empty when
///   `isSupabaseLoggedSafely` is false).
///
/// The handler is idempotent within an app session — the first detection
/// performs the sign-out; subsequent detections are no-ops.
class AccountDeletionHandler {
  static bool _signOutInProgress = false;
  static bool _signedOutForDeletion = false;

  /// True if the supplied error or its serialized form indicates the
  /// account has been soft-deleted on the server side (HTTP 403 +
  /// `ACCOUNT_DELETED` code in the Edge Function response details).
  ///
  /// Provide [error] (preferred — runtime catch path) or [sentryValue]
  /// (the serialized `event.exceptions[0].value` string from Sentry's
  /// beforeSend hook). Either is sufficient.
  static bool isAccountDeleted({Object? error, String? sentryValue}) {
    if (error is FunctionException) {
      if (error.status != 403) return false;
      final details = error.details;
      if (details is Map) {
        final inner = details['error'];
        if (inner is Map && inner['code'] == 'ACCOUNT_DELETED') return true;
      }
      // Fall through to string match — covers cases where details was a
      // plain string body.
      return error.toString().contains('ACCOUNT_DELETED');
    }
    final value = sentryValue ?? error?.toString() ?? '';
    return value.contains('ACCOUNT_DELETED');
  }

  /// Performs a one-shot sign-out so the deleted account stops triggering
  /// 403s on every Edge Function call.
  ///
  /// Returns `true` if a sign-out was performed (or was already performed
  /// during this app session). Returns `false` only if a sign-out is
  /// currently in-flight and another call invokes it concurrently — the
  /// in-flight call still finishes the work.
  ///
  /// Falls back to `supabase.auth.signOut()` if the higher-level
  /// [AuthService] sign-out throws — the goal is to invalidate the
  /// session no matter what so the next provider build short-circuits.
  static Future<bool> signOutForAccountDeleted() async {
    if (_signedOutForDeletion) return true;
    if (_signOutInProgress) return false;
    _signOutInProgress = true;
    try {
      logger.w('🚫 ACCOUNT_DELETED detected — clearing local session');
      try {
        await AuthService().signOut();
      } catch (e, s) {
        logger.w(
          'AuthService.signOut failed; falling back to supabase.auth.signOut',
          error: e,
          stackTrace: s,
        );
        try {
          await supabase.auth.signOut();
        } catch (e2, s2) {
          logger.e(
            'supabase.auth.signOut also failed — session may persist until next launch',
            error: e2,
            stackTrace: s2,
          );
        }
      }
      _signedOutForDeletion = true;
      return true;
    } finally {
      _signOutInProgress = false;
    }
  }

  /// Resets the internal latch so the handler can sign out again. Test only.
  static void resetForTests() {
    _signedOutForDeletion = false;
    _signOutInProgress = false;
  }

  /// Whether the handler has already triggered a sign-out this session.
  /// Test/diagnostic only.
  static bool get hasSignedOutForTests => _signedOutForDeletion;
}
