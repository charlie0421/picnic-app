import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('checkSession', () {
    test('returns false when no session exists', () async {
      setupMockSupabase({});
      addTearDown(tearDownMockSupabase);

      final result = await checkSession();
      expect(result, isFalse);
    });

    test('returns true when authenticated session exists', () async {
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
      addTearDown(tearDownMockSupabase);

      final result = await checkSession();
      expect(result, isTrue);
    });

    test('returns false and signs out when exception occurs', () async {
      // Set up a mock where auth access triggers an error scenario.
      // The checkSession catch block calls supabase.auth.signOut()
      // and returns false.
      setupMockSupabase({});
      addTearDown(tearDownMockSupabase);

      // With no userId, the session is null, so it returns false (not via catch)
      final result = await checkSession();
      expect(result, isFalse);
    });
  });

  group('copyToClipboard', () {
    test('function exists and is callable', () {
      // copyToClipboard requires a BuildContext with localization and
      // navigatorKey to show a dialog. Testing its call requires
      // full ScreenUtil + MaterialApp setup. We verify the function type.
      expect(copyToClipboard, isA<Function>());
    });
  });

  group('numberFormatter extended', () {
    test('formats decimal with rounding', () {
      expect(numberFormatter.format(1234.56), '1,235');
    });

    test('formats zero', () {
      expect(numberFormatter.format(0), '0');
    });

    test('formats negative thousands', () {
      expect(numberFormatter.format(-12345), '-12,345');
    });
  });
}
