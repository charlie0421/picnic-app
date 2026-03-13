import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer_helper.dart';

void main() {
  group('AppInitializerHelper', () {
    // ---------------------------------------------------------------
    // shouldFilterSentryEvent
    // ---------------------------------------------------------------
    group('shouldFilterSentryEvent', () {
      test('filters when Sentry is disabled', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: false,
            isDebugMode: false,
            exceptionType: 'SomeError',
            exceptionValue: 'details',
          ),
          isTrue,
        );
      });

      test('filters in debug mode', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: true,
            exceptionType: 'SomeError',
            exceptionValue: 'details',
          ),
          isTrue,
        );
      });

      test('does not filter unknown exception types', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'UnknownError',
            exceptionValue: 'something went wrong',
          ),
          isFalse,
        );
      });

      // Network noise types
      for (final type in [
        'HTTPClientError',
        'NetworkError',
        'ClientException',
        'OSError',
        'AuthRetryableFetchException',
      ]) {
        test('filters network noise type: $type', () {
          expect(
            AppInitializerHelper.shouldFilterSentryEvent(
              sentryEnabled: true,
              isDebugMode: false,
              exceptionType: type,
              exceptionValue: '',
            ),
            isTrue,
          );
        });
      }

      test('filters TypeError with null check message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'TypeError',
            exceptionValue: 'Null check operator used on a null value',
          ),
          isTrue,
        );
      });

      test('does not filter TypeError with different message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'TypeError',
            exceptionValue: 'type int is not a subtype of String',
          ),
          isFalse,
        );
      });

      // Ad noise types
      for (final type in ['LoadAdError', 'AdError']) {
        test('filters ad noise type: $type', () {
          expect(
            AppInitializerHelper.shouldFilterSentryEvent(
              sentryEnabled: true,
              isDebugMode: false,
              exceptionType: type,
              exceptionValue: '',
            ),
            isTrue,
          );
        });
      }

      test('filters String exception with ad load failure Korean message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue: '광고 로드 실패: no fill',
          ),
          isTrue,
        );
      });

      test('filters String exception with ad load timeout Korean message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue: '광고 로드 시간 초과',
          ),
          isTrue,
        );
      });

      test('does not filter String exception with other message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue: 'something else',
          ),
          isFalse,
        );
      });

      test('filters FunctionException with 502', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'Edge Function returned 502',
          ),
          isTrue,
        );
      });

      test('does not filter FunctionException without 502', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'Edge Function returned 500',
          ),
          isFalse,
        );
      });

      test('filters PostgrestException with RLS policy', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'new row violates row-level security policy',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with DOCTYPE', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: '<!DOCTYPE html>',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with 502', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: '502 Bad Gateway',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with JWT expired', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'JWT expired',
          ),
          isTrue,
        );
      });

      test('does not filter PostgrestException with other message', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'column not found',
          ),
          isFalse,
        );
      });

      test('filters PlatformException with BAD_DECRYPT', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PlatformException',
            exceptionValue: 'BAD_DECRYPT error',
          ),
          isTrue,
        );
      });

      test('does not filter PlatformException without BAD_DECRYPT', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PlatformException',
            exceptionValue: 'permission denied',
          ),
          isFalse,
        );
      });

      test('filters when both Sentry disabled and debug mode', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: false,
            isDebugMode: true,
            exceptionType: 'ImportantError',
            exceptionValue: 'critical',
          ),
          isTrue,
        );
      });

      test('handles empty exception type and value', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: '',
            exceptionValue: '',
          ),
          isFalse,
        );
      });
    });

    // ---------------------------------------------------------------
    // isDuplicateDeepLink
    // ---------------------------------------------------------------
    group('isDuplicateDeepLink', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);

      test('returns false when lastUrl is null', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: null,
            lastTime: null,
            now: now,
          ),
          isFalse,
        );
      });

      test('returns false when URLs differ', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/2',
            lastTime: now.subtract(const Duration(milliseconds: 500)),
            now: now,
          ),
          isFalse,
        );
      });

      test('returns true for same URL within threshold', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/1',
            lastTime: now.subtract(const Duration(milliseconds: 500)),
            now: now,
          ),
          isTrue,
        );
      });

      test('returns false for same URL beyond threshold', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/1',
            lastTime: now.subtract(const Duration(milliseconds: 3000)),
            now: now,
          ),
          isFalse,
        );
      });

      test('returns false for same URL exactly at threshold', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/1',
            lastTime: now.subtract(const Duration(milliseconds: 2000)),
            now: now,
          ),
          isFalse,
        );
      });

      test('custom threshold works', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/1',
            lastTime: now.subtract(const Duration(milliseconds: 4000)),
            now: now,
            threshold: const Duration(milliseconds: 5000),
          ),
          isTrue,
        );
      });

      test('returns false when lastTime is null but URLs match', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/vote/detail/1',
            lastUrl: 'https://example.com/vote/detail/1',
            lastTime: null,
            now: now,
          ),
          isFalse,
        );
      });

      test('handles empty URL strings', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: '',
            lastUrl: '',
            lastTime: now.subtract(const Duration(milliseconds: 500)),
            now: now,
          ),
          isTrue,
        );
      });
    });

    // ---------------------------------------------------------------
    // parseDeepLinkUrl
    // ---------------------------------------------------------------
    group('parseDeepLinkUrl', () {
      test('returns null for empty URL', () {
        // Uri.parse('') gives empty path segments
        final result = AppInitializerHelper.parseDeepLinkUrl('');
        expect(result, isNull);
      });

      test('parses vote detail URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/123',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'vote');
        expect(result.page, 'detail');
        expect(result.id, '123');
      });

      test('parses vote list URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/list',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'vote');
        expect(result.page, 'list');
        expect(result.id, isNull);
      });

      test('parses community home URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/community/home',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'community');
        expect(result.page, 'home');
      });

      test('parses community board_detail URL with ID', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/community/board_detail/42',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'community');
        expect(result.page, 'board_detail');
        expect(result.id, '42');
      });

      test('parses notice URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/notice/5',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'notice');
        expect(result.page, '5');
      });

      test('parses post URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/post/abc123',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'post');
        expect(result.page, 'abc123');
      });

      test('parses qna URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/qna/99',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'qna');
        expect(result.page, '99');
      });

      test('parses URL with query parameters', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/123?type=achieve',
        );
        expect(result, isNotNull);
        expect(result!.queryParams['type'], 'achieve');
      });

      test('parses URL with multiple query parameters', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/1?type=achieve&ref=push',
        );
        expect(result, isNotNull);
        expect(result!.queryParams['type'], 'achieve');
        expect(result.queryParams['ref'], 'push');
      });

      test('parses single-segment URL', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/terms',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'terms');
        expect(result.page, isNull);
        expect(result.id, isNull);
      });

      test('parses relative path URL', () {
        // Uri.parse handles relative paths
        final result = AppInitializerHelper.parseDeepLinkUrl(
          '/vote/detail/5',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'vote');
        expect(result.page, 'detail');
        expect(result.id, '5');
      });
    });

    // ---------------------------------------------------------------
    // calculateSplashRemainingTime
    // ---------------------------------------------------------------
    group('calculateSplashRemainingTime', () {
      test('returns zero when elapsed exceeds min duration', () {
        expect(
          AppInitializerHelper.calculateSplashRemainingTime(
            elapsed: const Duration(milliseconds: 3000),
            minDuration: const Duration(milliseconds: 2000),
          ),
          Duration.zero,
        );
      });

      test('returns zero when elapsed equals min duration', () {
        expect(
          AppInitializerHelper.calculateSplashRemainingTime(
            elapsed: const Duration(milliseconds: 2000),
            minDuration: const Duration(milliseconds: 2000),
          ),
          Duration.zero,
        );
      });

      test('returns remaining time when elapsed is less than min', () {
        expect(
          AppInitializerHelper.calculateSplashRemainingTime(
            elapsed: const Duration(milliseconds: 500),
            minDuration: const Duration(milliseconds: 2000),
          ),
          const Duration(milliseconds: 1500),
        );
      });

      test('returns full duration when elapsed is zero', () {
        expect(
          AppInitializerHelper.calculateSplashRemainingTime(
            elapsed: Duration.zero,
            minDuration: const Duration(milliseconds: 2000),
          ),
          const Duration(milliseconds: 2000),
        );
      });

      test('handles custom min durations', () {
        expect(
          AppInitializerHelper.calculateSplashRemainingTime(
            elapsed: const Duration(milliseconds: 100),
            minDuration: const Duration(milliseconds: 5000),
          ),
          const Duration(milliseconds: 4900),
        );
      });

      test('handles microsecond precision', () {
        final result = AppInitializerHelper.calculateSplashRemainingTime(
          elapsed: const Duration(microseconds: 500),
          minDuration: const Duration(milliseconds: 2000),
        );
        // 2000ms - 500us = 1999500us = 1999ms (int truncation)
        expect(result.inMilliseconds, equals(1999));
        expect(result.inMicroseconds, equals(1999500));
      });
    });

    // ---------------------------------------------------------------
    // DeepLinkParseResult
    // ---------------------------------------------------------------
    group('DeepLinkParseResult', () {
      test('stores all fields correctly', () {
        const result = DeepLinkParseResult(
          portal: 'vote',
          page: 'detail',
          id: '123',
          queryParams: {'type': 'achieve'},
        );
        expect(result.portal, 'vote');
        expect(result.page, 'detail');
        expect(result.id, '123');
        expect(result.queryParams['type'], 'achieve');
      });

      test('default queryParams is empty map', () {
        const result = DeepLinkParseResult(portal: 'test');
        expect(result.queryParams, isEmpty);
        expect(result.page, isNull);
        expect(result.id, isNull);
      });
    });

    // ---------------------------------------------------------------
    // parseDeepLinkUrl - additional edge cases
    // ---------------------------------------------------------------
    group('parseDeepLinkUrl - additional', () {
      test('URL with only scheme and host returns null (no path segments)', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com',
        );
        // Uri.parse('https://example.com').pathSegments is empty
        expect(result, isNull);
      });

      test('URL with trailing slash returns null (empty path segments)', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/',
        );
        // Uri.parse('https://example.com/').pathSegments = [] (empty)
        expect(result, isNull);
      });

      test('deep link with 4+ path segments', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/123/extra/path',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'vote');
        expect(result.page, 'detail');
        expect(result.id, '123');
        // Extra segments are not captured but don't cause errors
      });

      test('custom scheme deep link', () {
        // picnic://vote/detail/42 -> host=vote, pathSegments=[detail, 42]
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'picnic://vote/detail/42',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'detail');
        expect(result.page, '42');
        expect(result.id, isNull);
      });

      test('URL with fragment', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/1#section',
        );
        expect(result, isNotNull);
        expect(result!.portal, 'vote');
        expect(result.id, '1');
      });

      test('URL with encoded characters', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/community/board_detail/hello%20world',
        );
        expect(result, isNotNull);
        expect(result!.id, 'hello world');
      });

      test('URL with empty query parameter value', () {
        final result = AppInitializerHelper.parseDeepLinkUrl(
          'https://example.com/vote/detail/1?type=',
        );
        expect(result, isNotNull);
        expect(result!.queryParams['type'], '');
      });
    });

    // ---------------------------------------------------------------
    // shouldFilterSentryEvent - additional negative cases
    // ---------------------------------------------------------------
    group('shouldFilterSentryEvent - additional', () {
      test('does not filter regular StateError', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'StateError',
            exceptionValue: 'Bad state: No element',
          ),
          isFalse,
        );
      });

      test('does not filter FormatException', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FormatException',
            exceptionValue: 'Invalid format',
          ),
          isFalse,
        );
      });

      test('FunctionException without 502 is not filtered', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'timeout',
          ),
          isFalse,
        );
      });

      test('String type with unrelated message is not filtered', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue: 'some other string error',
          ),
          isFalse,
        );
      });

      test('TypeError without null check message is not filtered', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'TypeError',
            exceptionValue: 'Expected a value of type int',
          ),
          isFalse,
        );
      });
    });

    // ---------------------------------------------------------------
    // isDuplicateDeepLink - additional
    // ---------------------------------------------------------------
    group('isDuplicateDeepLink - additional', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);

      test('1ms before threshold is duplicate', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/test',
            lastUrl: 'https://example.com/test',
            lastTime: now.subtract(const Duration(milliseconds: 1999)),
            now: now,
          ),
          isTrue,
        );
      });

      test('zero threshold means any matching URL at same time is not duplicate', () {
        expect(
          AppInitializerHelper.isDuplicateDeepLink(
            url: 'https://example.com/test',
            lastUrl: 'https://example.com/test',
            lastTime: now,
            now: now,
            threshold: Duration.zero,
          ),
          isFalse,
        );
      });
    });
  });
}
