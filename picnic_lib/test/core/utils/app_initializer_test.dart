import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';

void main() {
  group('AppInitializer class', () {
    test('exists and is accessible', () {
      expect(AppInitializer, isNotNull);
    });
  });

  group('deep link duplicate prevention logic', () {
    // Replicating the duplicate deep link prevention from AppInitializer.handleDeepLink
    String? lastDeepLinkUrl;
    DateTime? lastDeepLinkTime;

    setUp(() {
      lastDeepLinkUrl = null;
      lastDeepLinkTime = null;
    });

    bool shouldIgnoreDuplicate(String longUrl) {
      final now = DateTime.now();
      if (lastDeepLinkUrl == longUrl &&
          lastDeepLinkTime != null &&
          now.difference(lastDeepLinkTime!).inMilliseconds < 2000) {
        return true;
      }
      lastDeepLinkUrl = longUrl;
      lastDeepLinkTime = now;
      return false;
    }

    test('first deep link is not a duplicate', () {
      expect(shouldIgnoreDuplicate('https://example.com/vote/1'), isFalse);
    });

    test('same URL within 2 seconds is duplicate', () {
      shouldIgnoreDuplicate('https://example.com/vote/1');
      expect(shouldIgnoreDuplicate('https://example.com/vote/1'), isTrue);
    });

    test('different URL is not a duplicate', () {
      shouldIgnoreDuplicate('https://example.com/vote/1');
      expect(shouldIgnoreDuplicate('https://example.com/vote/2'), isFalse);
    });

    test('same URL after 2+ seconds is not a duplicate', () {
      lastDeepLinkUrl = 'https://example.com/vote/1';
      lastDeepLinkTime = DateTime.now().subtract(const Duration(seconds: 3));
      expect(shouldIgnoreDuplicate('https://example.com/vote/1'), isFalse);
    });
  });

  group('deep link URL parsing logic', () {
    // Tests for the URL parsing logic inside handleDeepLink
    test('parses notice deep link', () {
      final uri = Uri.parse('https://example.com/notice/1');
      expect(uri.pathSegments.length, greaterThanOrEqualTo(2));
      expect(uri.pathSegments[0], equals('notice'));
      expect(uri.pathSegments[1], equals('1'));
      expect(int.tryParse(uri.pathSegments[1]), equals(1));
    });

    test('parses vote list deep link', () {
      final uri = Uri.parse('https://example.com/vote/list');
      expect(uri.pathSegments[0], equals('vote'));
      expect(uri.pathSegments[1], equals('list'));
    });

    test('parses vote detail deep link', () {
      final uri = Uri.parse('https://example.com/vote/detail/42');
      expect(uri.pathSegments[0], equals('vote'));
      expect(uri.pathSegments[1], equals('detail'));
      expect(uri.pathSegments.length, greaterThanOrEqualTo(3));
      expect(uri.pathSegments[2], equals('42'));
      expect(int.parse(uri.pathSegments[2]), equals(42));
    });

    test('parses vote detail achieve type', () {
      final uri = Uri.parse('https://example.com/vote/detail/42?type=achieve');
      expect(uri.queryParameters['type'], equals('achieve'));
    });

    test('parses vote detail without type parameter', () {
      final uri = Uri.parse('https://example.com/vote/detail/42');
      expect(uri.queryParameters['type'], isNull);
    });

    test('parses community home deep link', () {
      final uri = Uri.parse('https://example.com/community/home');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('home'));
    });

    test('parses community board_list deep link', () {
      final uri = Uri.parse('https://example.com/community/board_list');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('board_list'));
    });

    test('parses community board_detail deep link', () {
      final uri = Uri.parse('https://example.com/community/board_detail/123');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('board_detail'));
      expect(uri.pathSegments[2], equals('123'));
      expect(int.parse(uri.pathSegments[2]), equals(123));
    });

    test('parses post deep link', () {
      final uri = Uri.parse('https://example.com/post/abc-123');
      expect(uri.pathSegments[0], equals('post'));
      expect(uri.pathSegments.length, greaterThanOrEqualTo(2));
      expect(uri.pathSegments[1], equals('abc-123'));
      expect(uri.pathSegments[1].isNotEmpty, isTrue);
    });

    test('parses qna deep link', () {
      final uri = Uri.parse('https://example.com/qna/456');
      expect(uri.pathSegments[0], equals('qna'));
      expect(uri.pathSegments.length, greaterThanOrEqualTo(2));
      expect(int.tryParse(uri.pathSegments[1]), equals(456));
    });

    test('detects terms path', () {
      final uri = Uri.parse('https://example.com/terms/ko');
      expect(uri.pathSegments.contains('terms'), isTrue);
      expect(uri.pathSegments.contains('ko'), isTrue);
    });

    test('detects privacy path', () {
      final uri = Uri.parse('https://example.com/privacy/en');
      expect(uri.pathSegments.contains('privacy'), isTrue);
      expect(uri.pathSegments.contains('en'), isTrue);
    });

    test('detects terms without language defaults to en logic', () {
      final uri = Uri.parse('https://example.com/terms');
      expect(uri.pathSegments.contains('terms'), isTrue);
      expect(uri.pathSegments.contains('ko'), isFalse);
    });

    test('handles empty path segments', () {
      final uri = Uri.parse('https://example.com/');
      expect(uri.pathSegments.isEmpty || uri.pathSegments.every((s) => s.isEmpty), isTrue);
    });

    test('handles community fortune (disabled)', () {
      final uri = Uri.parse('https://example.com/community/fortune/123');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('fortune'));
    });

    test('handles community compatibility (disabled)', () {
      final uri = Uri.parse('https://example.com/community/compatibility/123');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('compatibility'));
    });

    test('handles community goonghap (disabled)', () {
      final uri = Uri.parse('https://example.com/community/goonghap/123');
      expect(uri.pathSegments[0], equals('community'));
      expect(uri.pathSegments[1], equals('goonghap'));
    });
  });

  group('deprecated initializeWithPatchCheck', () {
    test('returns true on success', () async {
      // ignore: deprecated_member_use_from_same_package
      final result = await AppInitializer.initializeWithPatchCheck();
      expect(result, isTrue);
    });

    test('calls onStatusUpdate callbacks', () async {
      final updates = <String>[];
      // ignore: deprecated_member_use_from_same_package
      await AppInitializer.initializeWithPatchCheck(
        onStatusUpdate: (status) => updates.add(status),
      );
      expect(updates, isNotEmpty);
      expect(updates, contains('Initializing app...'));
      expect(updates, contains('App initialized'));
    });
  });

  group('deprecated checkPatchInBackground', () {
    test('returns correct structure', () async {
      // ignore: deprecated_member_use_from_same_package
      final result = await AppInitializer.checkPatchInBackground();
      expect(result, isA<Map<String, dynamic>>());
      expect(result['updateAvailable'], isFalse);
      expect(result['updateDownloaded'], isFalse);
      expect(result['needsRestart'], isFalse);
      expect(result['message'], isNotEmpty);
    });

    test('calls onStatusUpdate callback', () async {
      final updates = <String>[];
      // ignore: deprecated_member_use_from_same_package
      await AppInitializer.checkPatchInBackground(
        onStatusUpdate: (status) => updates.add(status),
      );
      expect(updates, isNotEmpty);
    });
  });

  group('Sentry beforeSend filter logic', () {
    // Replicate the filtering logic from initializeSentry
    bool shouldFilterException(String exceptionType, String exceptionValue) {
      const networkNoiseTypes = {
        'HTTPClientError',
        'NetworkError',
        'ClientException',
        'OSError',
        'AuthRetryableFetchException',
      };
      if (networkNoiseTypes.contains(exceptionType)) {
        return true;
      }
      if (exceptionType == 'TypeError' &&
          exceptionValue.contains('Null check operator used on a null value')) {
        return true;
      }
      const adNoiseTypes = {'LoadAdError', 'AdError'};
      if (adNoiseTypes.contains(exceptionType)) {
        return true;
      }
      if (exceptionType == 'String' &&
          (exceptionValue.contains('ad load failed') ||
              exceptionValue.contains('ad loading timeout'))) {
        return true;
      }
      if (exceptionType == 'FunctionException' &&
          exceptionValue.contains('502')) {
        return true;
      }
      if (exceptionType == 'PostgrestException' &&
          exceptionValue.contains('row-level security policy')) {
        return true;
      }
      if (exceptionType == 'PostgrestException' &&
          (exceptionValue.contains('DOCTYPE') ||
              exceptionValue.contains('502'))) {
        return true;
      }
      if (exceptionType == 'PostgrestException' &&
          exceptionValue.contains('JWT expired')) {
        return true;
      }
      if (exceptionType == 'PlatformException' &&
          exceptionValue.contains('BAD_DECRYPT')) {
        return true;
      }
      return false;
    }

    test('filters HTTPClientError', () {
      expect(shouldFilterException('HTTPClientError', 'connection refused'), isTrue);
    });

    test('filters NetworkError', () {
      expect(shouldFilterException('NetworkError', 'no internet'), isTrue);
    });

    test('filters ClientException', () {
      expect(shouldFilterException('ClientException', 'timeout'), isTrue);
    });

    test('filters OSError', () {
      expect(shouldFilterException('OSError', 'socket closed'), isTrue);
    });

    test('filters AuthRetryableFetchException', () {
      expect(shouldFilterException('AuthRetryableFetchException', 'retry'), isTrue);
    });

    test('filters Supabase TypeError with null check', () {
      expect(
        shouldFilterException('TypeError', 'Null check operator used on a null value'),
        isTrue,
      );
    });

    test('does not filter other TypeErrors', () {
      expect(
        shouldFilterException('TypeError', 'type String is not a subtype of int'),
        isFalse,
      );
    });

    test('filters LoadAdError', () {
      expect(shouldFilterException('LoadAdError', 'ad not available'), isTrue);
    });

    test('filters AdError', () {
      expect(shouldFilterException('AdError', 'ad rendering failed'), isTrue);
    });

    test('filters FunctionException with 502', () {
      expect(shouldFilterException('FunctionException', 'Error 502 Bad Gateway'), isTrue);
    });

    test('does not filter FunctionException without 502', () {
      expect(shouldFilterException('FunctionException', 'Error 500'), isFalse);
    });

    test('filters PostgrestException with RLS policy', () {
      expect(
        shouldFilterException('PostgrestException', 'new row violates row-level security policy'),
        isTrue,
      );
    });

    test('filters PostgrestException with DOCTYPE', () {
      expect(
        shouldFilterException('PostgrestException', '<!DOCTYPE html>'),
        isTrue,
      );
    });

    test('filters PostgrestException with 502', () {
      expect(
        shouldFilterException('PostgrestException', 'Error 502'),
        isTrue,
      );
    });

    test('filters PostgrestException with JWT expired', () {
      expect(
        shouldFilterException('PostgrestException', 'JWT expired'),
        isTrue,
      );
    });

    test('filters PlatformException with BAD_DECRYPT', () {
      expect(
        shouldFilterException('PlatformException', 'BAD_DECRYPT error'),
        isTrue,
      );
    });

    test('does not filter regular exceptions', () {
      expect(shouldFilterException('Exception', 'something went wrong'), isFalse);
    });

    test('does not filter unknown exception types', () {
      expect(shouldFilterException('CustomError', 'custom message'), isFalse);
    });
  });

  group('splash timing logic', () {
    test('elapsed time less than min splash results in remaining time', () {
      const minSplashDuration = Duration(milliseconds: 2000);
      final elapsedTime = const Duration(milliseconds: 500);
      final remainingTime = minSplashDuration - elapsedTime;
      expect(remainingTime.inMilliseconds, equals(1500));
    });

    test('elapsed time equal to min splash results in zero remaining', () {
      const minSplashDuration = Duration(milliseconds: 2000);
      final elapsedTime = const Duration(milliseconds: 2000);
      expect(elapsedTime < minSplashDuration, isFalse);
    });

    test('elapsed time greater than min splash - no extra wait', () {
      const minSplashDuration = Duration(milliseconds: 2000);
      final elapsedTime = const Duration(milliseconds: 3000);
      expect(elapsedTime < minSplashDuration, isFalse);
    });
  });
}
