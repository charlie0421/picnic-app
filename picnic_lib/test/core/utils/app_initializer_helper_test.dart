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

      // -------- Coverage gap fixes (production-leak issues on 1.2.27) --------

      test('filters HttpException as network noise (PICNIC-APP-49W)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'HttpException',
            exceptionValue: 'HttpException: Invalid statusCode: 502, '
                'uri = https://supabase.co/storage/...',
          ),
          isTrue,
        );
      });

      test('filters SocketException as network noise', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'SocketException',
            exceptionValue: 'Failed host lookup',
          ),
          isTrue,
        );
      });

      test('filters FunctionException with 503 (PICNIC-APP-4ZY/4ZX/4EN)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'FunctionException(status: 503, details: '
                '{code: SUPABASE_EDGE_RUNTIME_ERROR, '
                'message: Service is temporarily unavailable})',
          ),
          isTrue,
        );
      });

      test('filters FunctionException with 504 gateway timeout', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'Edge Function returned 504',
          ),
          isTrue,
        );
      });

      test('filters FunctionException with SUPABASE_EDGE_RUNTIME_ERROR code',
          () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'Error: SUPABASE_EDGE_RUNTIME_ERROR',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException wrapping NetworkError (PICNIC-APP-47)',
          () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'PostgrestException(message: '
                '{"error": "NetworkError: Network connection error: '
                'ClientException with SocketException: Failed host lookup"})',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException wrapping SocketException', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'SocketException: Software caused connection abort',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with Failed host lookup', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'Failed host lookup: api.supabase.co',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with Connection closed', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'Connection closed before full header was received',
          ),
          isTrue,
        );
      });

      test('still does not filter actionable PostgrestException messages', () {
        // Real bugs (RLS misconfig in code, missing column) should still
        // surface. Only network-environment noise is dropped.
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'column "user_id" does not exist',
          ),
          isFalse,
        );
      });

      test('does not filter FunctionException with 500 (real server bug)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue: 'Internal Server Error 500',
          ),
          isFalse,
        );
      });

      // -------- PICNIC-APP-4ZX: wrapped network/timeout in FunctionException
      test('filters FunctionException wrapping TimeoutException '
          '(PICNIC-APP-4ZX)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 500, details: {error: '
                'TimeoutException after 0:00:30.000000: Request timed out '
                'after 30 seconds}, reasonPhrase: Network Error)',
          ),
          isTrue,
        );
      });

      test('filters FunctionException wrapping Software caused '
          'connection abort (Android net swap)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 500, details: {error: '
                'NetworkError: Network connection error: ClientException: '
                'Software caused connection abort, '
                'uri=https://xtijtefcycoeqludlngc.supabase.co/functions/v1/'
                'attendance-check}, reasonPhrase: Network Error)',
          ),
          isTrue,
        );
      });

      test('filters FunctionException wrapping Connection reset by peer', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 500, details: {error: '
                'ClientException: Failed to send request: ClientException: '
                'Connection reset by peer, '
                'uri=https://xtijtefcycoeqludlngc.supabase.co/functions/v1/'
                'attendance-check}, reasonPhrase: Network Error)',
          ),
          isTrue,
        );
      });

      test('filters FunctionException wrapping Network is unreachable', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 500, details: {error: '
                'NetworkError: Network connection error: ClientException with '
                'SocketException: Connection failed (OS Error: Network is '
                'unreachable, errno = 101), '
                'address = xtijtefcycoeqludlngc.supabase.co}, '
                'reasonPhrase: Network Error)',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException wrapping TimeoutException', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue:
                'PostgrestException(message: {"error": "TimeoutException '
                'after 0:00:30.000000: Request timed out after 30 seconds"}, '
                'code: 500, details: Network Error, hint: null)',
          ),
          isTrue,
        );
      });

      // -------- 1.2.28 prod-leak fixes --------

      test('filters FunctionException ACCOUNT_DELETED — handled reactively '
          'by AccountDeletionHandler', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 403, details: {success: false, '
                'error: {message: Account deleted, code: ACCOUNT_DELETED}}, '
                'reasonPhrase: Forbidden)',
          ),
          isTrue,
        );
      });

      test('filters FunctionException SIGNUP_UNVERIFIED — email unverified '
          'business signal (PICNIC-APP-4EN)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 403, details: {error: '
                'signup_unverified, code: SIGNUP_UNVERIFIED}, '
                'reasonPhrase: Forbidden)',
          ),
          isTrue,
        );
      });

      test('filters String-typed PostgrestException wrapping Failed host '
          'lookup (PICNIC-APP-3R)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue:
                'PostgrestException(message: {"error": "NetworkError: '
                'Network connection error: ClientException with '
                'SocketException: Failed host lookup: '
                '\'xtijtefcycoeqludlngc.supabase.co\' '
                '(OS Error: No address associated with hostname, errno = 7)"}, '
                'code: 500, details: Network Error, hint: null)',
          ),
          isTrue,
        );
      });

      test('filters String-typed AuthRetryableFetchException wrapping '
          'HandshakeException (PICNIC-APP-4RP)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue:
                'AuthRetryableFetchException(message: {"error": '
                '"ClientException: Failed to send request: HandshakeException: '
                'Connection terminated during handshake, '
                'uri=https://xtijtefcycoeqludlngc.supabase.co/auth/v1/token?'
                'grant_type=refresh_token"}, statusCode: 500)',
          ),
          isTrue,
        );
      });

      test('does not filter String type with unrelated message', () {
        // 회귀 보호: 일반 String throw 는 그대로 캡쳐
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'String',
            exceptionValue: 'some unrelated business error',
          ),
          isFalse,
        );
      });

      test('filters HandshakeException as network noise (TLS failures, '
          'PICNIC-APP-47 in 1.2.28)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'HandshakeException',
            exceptionValue: 'Connection terminated during handshake',
          ),
          isTrue,
        );
      });

      test('filters TlsException as network noise', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'TlsException',
            exceptionValue: 'Handshake error in client',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException wrapping HandshakeException '
          '(real 1.2.28 prod sample)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue: 'PostgrestException(message: '
                '{"error": "ClientException: Failed to send request: '
                'HandshakeException: Connection terminated during handshake, '
                'uri=https://supabase.co/rest/v1/artist_user_bookmark"})',
          ),
          isTrue,
        );
      });

      test('filters PostgrestException with Connection terminated', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PostgrestException',
            exceptionValue:
                'Connection terminated during keep-alive negotiation',
          ),
          isTrue,
        );
      });

      test('filters PlatformException(already_active, Image picker) — '
          'PICNIC-APP-VQ double-tap noise', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PlatformException',
            exceptionValue: 'PlatformException(already_active, '
                'Image picker is already active, null, null)',
          ),
          isTrue,
        );
      });

      test('does NOT filter PlatformException already_active for unrelated '
          'plugins (only Image picker is noise)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'PlatformException',
            exceptionValue: 'PlatformException(already_active, '
                'Camera is already active, null, null)',
          ),
          isFalse,
        );
      });

      test('filters AuthException(Code verifier could not be found) — '
          'PKCE storage race, PICNIC-APP-504', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthException',
            exceptionValue: 'AuthException(message: '
                'Code verifier could not be found in local storage., '
                'statusCode: null)',
          ),
          isTrue,
        );
      });

      test('filters AuthApiException(Invalid Refresh Token: Already Used) — '
          'PICNIC-APP-4GW token rotation race', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthApiException',
            exceptionValue: 'AuthApiException(message: '
                'Invalid Refresh Token: Already Used, '
                'statusCode: 400, code: refresh_token_already_used)',
          ),
          isTrue,
        );
      });

      test('filters AuthApiException(Refresh Token Not Found) — '
          'PICNIC-APP-56J stale session', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthApiException',
            exceptionValue: 'AuthApiException(message: '
                'Refresh Token Not Found, statusCode: 400, '
                'code: refresh_token_not_found)',
          ),
          isTrue,
        );
      });

      test('filters AuthSessionMissingException — self-healing re-login '
          'flow (PICNIC-APP-508)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthSessionMissingException',
            exceptionValue: 'AuthSessionMissingException(message: '
                'Auth session missing!, statusCode: 400)',
          ),
          isTrue,
        );
      });

      test('filters AuthApiException(User is banned) — admin policy block, '
          'UI handles it (PICNIC-APP-4RJ: 39u/183e accumulated)', () {
        // 이전 결정 (NOT filter, "handled separately") 은 실제 누적 데이터로
        // 뒤집힘 — UI 가 user_banned 안내 후 종료하는 정상 흐름이므로 Sentry
        // 노이즈로 처리.
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthApiException',
            exceptionValue: 'AuthApiException(message: User is banned, '
                'statusCode: 403, code: user_banned)',
          ),
          isTrue,
        );
      });

      test('still does NOT filter unrelated AuthApiException — e.g. real '
          'authorization bug should surface', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'AuthApiException',
            exceptionValue: 'AuthApiException(message: '
                'something_unexpected, statusCode: 500)',
          ),
          isFalse,
        );
      });

      test('still does NOT filter FunctionException 403 with a different '
          'error code (e.g. real authorization bug should surface)', () {
        expect(
          AppInitializerHelper.shouldFilterSentryEvent(
            sentryEnabled: true,
            isDebugMode: false,
            exceptionType: 'FunctionException',
            exceptionValue:
                'FunctionException(status: 403, details: {error: '
                '{code: PERMISSION_DENIED, message: Not allowed}})',
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
