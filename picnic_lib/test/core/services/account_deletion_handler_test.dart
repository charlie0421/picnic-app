import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/account_deletion_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AccountDeletionHandler.isAccountDeleted', () {
    test('matches FunctionException 403 with ACCOUNT_DELETED code in details',
        () {
      final e = FunctionException(
        status: 403,
        details: {
          'success': false,
          'error': {'code': 'ACCOUNT_DELETED', 'message': 'Account deleted'},
        },
        reasonPhrase: 'Forbidden',
      );
      expect(AccountDeletionHandler.isAccountDeleted(error: e), isTrue);
    });

    test('rejects FunctionException 403 with a different error code', () {
      final e = FunctionException(
        status: 403,
        details: {
          'success': false,
          'error': {'code': 'FORBIDDEN', 'message': 'Not allowed'},
        },
        reasonPhrase: 'Forbidden',
      );
      expect(AccountDeletionHandler.isAccountDeleted(error: e), isFalse);
    });

    test('rejects FunctionException with non-403 status even when value contains '
        'ACCOUNT_DELETED — status guard prevents false positives', () {
      final e = FunctionException(
        status: 500,
        details: 'Server error mentioning ACCOUNT_DELETED in body somehow',
        reasonPhrase: 'Server Error',
      );
      // String body fallback inspects toString(), and FunctionException's
      // toString includes status — but the structured short-circuit on
      // status != 403 means we never look at the string. Result: false.
      expect(AccountDeletionHandler.isAccountDeleted(error: e), isFalse);
    });

    test('matches FunctionException 403 with string body containing ACCOUNT_DELETED',
        () {
      final e = FunctionException(
        status: 403,
        details: '{"error": {"code": "ACCOUNT_DELETED"}}',
        reasonPhrase: 'Forbidden',
      );
      expect(AccountDeletionHandler.isAccountDeleted(error: e), isTrue);
    });

    test('matches via sentryValue path (Sentry beforeSend simulation)', () {
      const value =
          'FunctionException(status: 403, details: {success: false, error: '
          '{message: Account deleted, code: ACCOUNT_DELETED}}, '
          'reasonPhrase: Forbidden)';
      expect(
        AccountDeletionHandler.isAccountDeleted(sentryValue: value),
        isTrue,
      );
    });

    test('rejects sentryValue without ACCOUNT_DELETED token', () {
      const value =
          'FunctionException(status: 503, details: {code: SUPABASE_EDGE_RUNTIME_ERROR})';
      expect(
        AccountDeletionHandler.isAccountDeleted(sentryValue: value),
        isFalse,
      );
    });

    test('returns false when neither error nor sentryValue is supplied', () {
      expect(AccountDeletionHandler.isAccountDeleted(), isFalse);
    });

    test('non-FunctionException error string with ACCOUNT_DELETED token still matches '
        '(defensive: catches wrapped errors)', () {
      final wrapped =
          Exception('wrapped error: ACCOUNT_DELETED happened upstream');
      expect(
        AccountDeletionHandler.isAccountDeleted(error: wrapped),
        isTrue,
      );
    });
  });

  group('AccountDeletionHandler.hasSignedOutForTests', () {
    setUp(AccountDeletionHandler.resetForTests);

    test('starts false on a fresh app session', () {
      expect(AccountDeletionHandler.hasSignedOutForTests, isFalse);
    });
  });
}
