import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_helper.dart';

void main() {
  // ===========================================================================
  // Token validation
  // ===========================================================================
  group('PushTokenHelper.isTokenValid', () {
    test('returns false for null', () {
      expect(PushTokenHelper.isTokenValid(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(PushTokenHelper.isTokenValid(''), isFalse);
    });

    test('returns true for non-empty string', () {
      expect(PushTokenHelper.isTokenValid('abc123'), isTrue);
    });

    test('returns true for long FCM-like token', () {
      expect(
        PushTokenHelper.isTokenValid(
          'dGVzdC10b2tlbi1mb3ItdGVzdGluZy1wdXJwb3Nlcy1vbmx5',
        ),
        isTrue,
      );
    });
  });

  group('PushTokenHelper.hasTokenChanged', () {
    test('null old token is always changed', () {
      expect(PushTokenHelper.hasTokenChanged(null, 'new'), isTrue);
    });

    test('empty old token is always changed', () {
      expect(PushTokenHelper.hasTokenChanged('', 'new'), isTrue);
    });

    test('same tokens are not changed', () {
      expect(PushTokenHelper.hasTokenChanged('abc', 'abc'), isFalse);
    });

    test('different tokens are changed', () {
      expect(PushTokenHelper.hasTokenChanged('old', 'new'), isTrue);
    });

    test('null new token with valid old token returns false', () {
      expect(PushTokenHelper.hasTokenChanged('old', null), isFalse);
    });

    test('empty new token with valid old token returns false', () {
      expect(PushTokenHelper.hasTokenChanged('old', ''), isFalse);
    });

    test('both null returns true (old is null)', () {
      expect(PushTokenHelper.hasTokenChanged(null, null), isTrue);
    });
  });

  // ===========================================================================
  // Token preview formatting
  // ===========================================================================
  group('PushTokenHelper.tokenPreview', () {
    test('null token returns "null"', () {
      expect(PushTokenHelper.tokenPreview(null), 'null');
    });

    test('empty token returns empty string', () {
      expect(PushTokenHelper.tokenPreview(''), '');
    });

    test('short token (< 12 chars) returned fully', () {
      expect(PushTokenHelper.tokenPreview('abc123'), 'abc123');
    });

    test('exactly 12 char token returned fully', () {
      expect(PushTokenHelper.tokenPreview('abcdefghijkl'), 'abcdefghijkl');
    });

    test('13 char token is truncated', () {
      expect(PushTokenHelper.tokenPreview('abcdefghijklm'), 'abcdefghijkl...');
    });

    test('long token is truncated to 12 + ellipsis', () {
      expect(
        PushTokenHelper.tokenPreview('abcdefghijklmnopqrstuvwxyz'),
        'abcdefghijkl...',
      );
    });

    test('single character token returned fully', () {
      expect(PushTokenHelper.tokenPreview('x'), 'x');
    });
  });

  // ===========================================================================
  // Platform string
  // ===========================================================================
  group('PushTokenHelper.platformString', () {
    test('ios', () {
      expect(PushTokenHelper.platformString('ios'), 'ios');
    });

    test('android', () {
      expect(PushTokenHelper.platformString('android'), 'android');
    });

    test('macos', () {
      expect(PushTokenHelper.platformString('macos'), 'macos');
    });

    test('windows', () {
      expect(PushTokenHelper.platformString('windows'), 'windows');
    });

    test('linux defaults to web', () {
      expect(PushTokenHelper.platformString('linux'), 'web');
    });

    test('fuchsia defaults to web', () {
      expect(PushTokenHelper.platformString('fuchsia'), 'web');
    });

    test('empty string defaults to web', () {
      expect(PushTokenHelper.platformString(''), 'web');
    });

    test('uppercase iOS is not matched (case-sensitive)', () {
      expect(PushTokenHelper.platformString('iOS'), 'web');
    });

    test('unknown platform defaults to web', () {
      expect(PushTokenHelper.platformString('chromeos'), 'web');
    });
  });

  // ===========================================================================
  // App language resolution
  // ===========================================================================
  group('PushTokenHelper.resolveAppLanguage', () {
    group('priority 1: appLanguage from LocaleService', () {
      test('Korean', () {
        expect(PushTokenHelper.resolveAppLanguage('ko', ''), 'ko');
      });

      test('English', () {
        expect(PushTokenHelper.resolveAppLanguage('en', ''), 'en');
      });

      test('Japanese', () {
        expect(PushTokenHelper.resolveAppLanguage('ja', ''), 'ja');
      });

      test('uppercase is lowered', () {
        expect(PushTokenHelper.resolveAppLanguage('KO', ''), 'ko');
      });

      test('zh-TW returns zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('zh-TW', ''), 'zh-TW');
      });

      test('zh_TW returns zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('zh_TW', ''), 'zh-TW');
      });

      test('appLanguage takes priority over deviceLocale', () {
        expect(PushTokenHelper.resolveAppLanguage('ja', 'ko_KR'), 'ja');
      });
    });

    group('priority 2: device locale fallback', () {
      test('ko_KR -> ko', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'ko_KR'), 'ko');
      });

      test('en_US -> en', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'en_US'), 'en');
      });

      test('ja_JP -> ja', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'ja_JP'), 'ja');
      });

      test('fr-FR (dash) -> fr', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'fr-FR'), 'fr');
      });

      test('de_DE (underscore) -> de', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'de_DE'), 'de');
      });
    });

    group('traditional Chinese locale variants', () {
      test('zh_TW locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh_TW'), 'zh-TW');
      });

      test('zh-TW locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh-TW'), 'zh-TW');
      });

      test('zh_HK locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh_HK'), 'zh-TW');
      });

      test('zh-HK locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh-HK'), 'zh-TW');
      });

      test('zh-Hant locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh-Hant'), 'zh-TW');
      });

      test('zh_Hant_TW locale -> zh-TW', () {
        expect(PushTokenHelper.resolveAppLanguage('', 'zh_Hant_TW'), 'zh-TW');
      });
    });

    group('fallback to en', () {
      test('both empty -> en', () {
        expect(PushTokenHelper.resolveAppLanguage('', ''), 'en');
      });
    });
  });

  // ===========================================================================
  // Notification payload construction
  // ===========================================================================
  group('PushTokenHelper.buildNotificationPayload', () {
    test('null data returns null', () {
      expect(PushTokenHelper.buildNotificationPayload(null), isNull);
    });

    test('data with action_url returns formatted string', () {
      final result = PushTokenHelper.buildNotificationPayload({
        'action_url': 'https://applink.picnic.fan/post/123',
        'other': 'data',
      });
      expect(result, 'action_url: https://applink.picnic.fan/post/123');
    });

    test('data without action_url returns toString()', () {
      final data = {'key': 'value'};
      expect(PushTokenHelper.buildNotificationPayload(data), data.toString());
    });

    test('empty map returns toString()', () {
      final data = <String, dynamic>{};
      expect(PushTokenHelper.buildNotificationPayload(data), data.toString());
    });

    test('action_url with empty value still uses action_url format', () {
      final result = PushTokenHelper.buildNotificationPayload({
        'action_url': '',
      });
      expect(result, 'action_url: ');
    });
  });

  // ===========================================================================
  // Action URL extraction
  // ===========================================================================
  group('PushTokenHelper.extractActionUrl', () {
    test('null payload returns null', () {
      expect(PushTokenHelper.extractActionUrl(null), isNull);
    });

    test('empty payload returns null', () {
      expect(PushTokenHelper.extractActionUrl(''), isNull);
    });

    test('payload without action_url returns null', () {
      expect(PushTokenHelper.extractActionUrl('some random text'), isNull);
    });

    test('extracts https URL from payload', () {
      expect(
        PushTokenHelper.extractActionUrl(
          'action_url: https://applink.picnic.fan/post/123',
        ),
        'https://applink.picnic.fan/post/123',
      );
    });

    test('extracts http URL from payload', () {
      expect(
        PushTokenHelper.extractActionUrl(
          'action_url: http://example.com/test',
        ),
        'http://example.com/test',
      );
    });

    test('extracts URL from stringified map', () {
      expect(
        PushTokenHelper.extractActionUrl(
          '{action_url: https://applink.picnic.fan/post/123}',
        ),
        'https://applink.picnic.fan/post/123',
      );
    });

    test('handles URL with query parameters', () {
      expect(
        PushTokenHelper.extractActionUrl(
          'action_url: https://applink.picnic.fan/post?id=123&lang=ko',
        ),
        'https://applink.picnic.fan/post?id=123&lang=ko',
      );
    });

    test('returns null when action_url key but no URL', () {
      expect(
        PushTokenHelper.extractActionUrl('action_url: not-a-url'),
        isNull,
      );
    });
  });

  // ===========================================================================
  // Foreground notification fields
  // ===========================================================================
  group('PushTokenHelper.resolveNotificationTitle', () {
    test('prefers notification title', () {
      expect(PushTokenHelper.resolveNotificationTitle('A', 'B'), 'A');
    });

    test('falls back to data title when notification title is null', () {
      expect(PushTokenHelper.resolveNotificationTitle(null, 'B'), 'B');
    });

    test('falls back to (no-title) when both are null', () {
      expect(PushTokenHelper.resolveNotificationTitle(null, null), '(no-title)');
    });

    test('empty notification title is used (not treated as null)', () {
      expect(PushTokenHelper.resolveNotificationTitle('', 'B'), '');
    });
  });

  group('PushTokenHelper.resolveNotificationBody', () {
    test('prefers notification body', () {
      expect(PushTokenHelper.resolveNotificationBody('A', 'B'), 'A');
    });

    test('falls back to data body when notification body is null', () {
      expect(PushTokenHelper.resolveNotificationBody(null, 'B'), 'B');
    });

    test('falls back to empty string when both are null', () {
      expect(PushTokenHelper.resolveNotificationBody(null, null), '');
    });
  });

  group('PushTokenHelper.shouldShowForegroundNotification', () {
    test('shows when title and body are valid', () {
      expect(
        PushTokenHelper.shouldShowForegroundNotification('Hello', 'World'),
        isTrue,
      );
    });

    test('does not show when title is (no-title)', () {
      expect(
        PushTokenHelper.shouldShowForegroundNotification('(no-title)', 'Body'),
        isFalse,
      );
    });

    test('does not show when body is empty', () {
      expect(
        PushTokenHelper.shouldShowForegroundNotification('Title', ''),
        isFalse,
      );
    });

    test('does not show when both are bad', () {
      expect(
        PushTokenHelper.shouldShowForegroundNotification('(no-title)', ''),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // Notification ID generation
  // ===========================================================================
  group('PushTokenHelper.generateNotificationId', () {
    test('returns value within 0..99999', () {
      final id = PushTokenHelper.generateNotificationId(
        DateTime(2024, 1, 1, 12, 0, 0),
      );
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThan(100000));
    });

    test('same timestamp produces same id', () {
      final ts = DateTime(2024, 6, 15, 10, 30, 45);
      expect(
        PushTokenHelper.generateNotificationId(ts),
        PushTokenHelper.generateNotificationId(ts),
      );
    });

    test('different timestamps produce different ids (most likely)', () {
      final id1 = PushTokenHelper.generateNotificationId(
        DateTime(2024, 1, 1, 0, 0, 0),
      );
      final id2 = PushTokenHelper.generateNotificationId(
        DateTime(2024, 1, 1, 0, 0, 1),
      );
      expect(id1, isNot(equals(id2)));
    });

    test('epoch zero returns zero', () {
      expect(
        PushTokenHelper.generateNotificationId(
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        0,
      );
    });
  });

  // ===========================================================================
  // Registration response classification
  // ===========================================================================
  group('PushTokenHelper.isRegistrationSuccess', () {
    test('200 is success', () {
      expect(PushTokenHelper.isRegistrationSuccess(200), isTrue);
    });

    test('201 is success', () {
      expect(PushTokenHelper.isRegistrationSuccess(201), isTrue);
    });

    test('299 is success', () {
      expect(PushTokenHelper.isRegistrationSuccess(299), isTrue);
    });

    test('300 is failure', () {
      expect(PushTokenHelper.isRegistrationSuccess(300), isFalse);
    });

    test('400 is failure', () {
      expect(PushTokenHelper.isRegistrationSuccess(400), isFalse);
    });

    test('500 is failure', () {
      expect(PushTokenHelper.isRegistrationSuccess(500), isFalse);
    });

    test('0 is success', () {
      expect(PushTokenHelper.isRegistrationSuccess(0), isTrue);
    });
  });

  // ===========================================================================
  // Error classification
  // ===========================================================================
  group('PushTokenHelper.classifyError', () {
    test('TimeoutException -> timeout', () {
      expect(PushTokenHelper.classifyError('TimeoutException'), 'timeout');
    });

    test('SocketException -> network', () {
      expect(PushTokenHelper.classifyError('SocketException'), 'network');
    });

    test('FunctionException with 401 -> auth', () {
      expect(
        PushTokenHelper.classifyError('FunctionException', statusCode: 401),
        'auth',
      );
    });

    test('FunctionException with 500 -> function_error', () {
      expect(
        PushTokenHelper.classifyError('FunctionException', statusCode: 500),
        'function_error',
      );
    });

    test('FunctionException without status -> function_error', () {
      expect(PushTokenHelper.classifyError('FunctionException'), 'function_error');
    });

    test('unknown error type -> unknown', () {
      expect(PushTokenHelper.classifyError('FormatException'), 'unknown');
    });

    test('empty string -> unknown', () {
      expect(PushTokenHelper.classifyError(''), 'unknown');
    });

    test('case insensitive matching', () {
      expect(PushTokenHelper.classifyError('timeoutexception'), 'timeout');
      expect(PushTokenHelper.classifyError('SOCKETEXCEPTION'), 'network');
    });
  });

  group('PushTokenHelper.isRetriableError', () {
    test('timeout is retriable', () {
      expect(PushTokenHelper.isRetriableError('timeout'), isTrue);
    });

    test('auth is retriable', () {
      expect(PushTokenHelper.isRetriableError('auth'), isTrue);
    });

    test('network is not retriable', () {
      expect(PushTokenHelper.isRetriableError('network'), isFalse);
    });

    test('function_error is not retriable', () {
      expect(PushTokenHelper.isRetriableError('function_error'), isFalse);
    });

    test('unknown is not retriable', () {
      expect(PushTokenHelper.isRetriableError('unknown'), isFalse);
    });
  });

  // ===========================================================================
  // Registration payload construction
  // ===========================================================================
  group('PushTokenHelper.buildRegistrationPayload', () {
    test('builds correct map', () {
      final payload = PushTokenHelper.buildRegistrationPayload(
        platform: 'ios',
        token: 'test-token',
        deviceLocale: 'ko',
      );
      expect(payload, {
        'platform': 'ios',
        'token': 'test-token',
        'device_locale': 'ko',
      });
    });

    test('preserves all values exactly', () {
      final payload = PushTokenHelper.buildRegistrationPayload(
        platform: 'android',
        token: 'abc123xyz',
        deviceLocale: 'zh-TW',
      );
      expect(payload['platform'], 'android');
      expect(payload['token'], 'abc123xyz');
      expect(payload['device_locale'], 'zh-TW');
    });

    test('handles empty strings', () {
      final payload = PushTokenHelper.buildRegistrationPayload(
        platform: '',
        token: '',
        deviceLocale: '',
      );
      expect(payload.length, 3);
      expect(payload['platform'], '');
    });
  });

  group('PushTokenHelper.buildAuthHeaders', () {
    test('builds Bearer header', () {
      final headers = PushTokenHelper.buildAuthHeaders('my-access-token');
      expect(headers, {'Authorization': 'Bearer my-access-token'});
    });

    test('includes full token in header value', () {
      const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test';
      final headers = PushTokenHelper.buildAuthHeaders(token);
      expect(headers['Authorization'], 'Bearer $token');
    });

    test('handles empty token', () {
      final headers = PushTokenHelper.buildAuthHeaders('');
      expect(headers['Authorization'], 'Bearer ');
    });
  });
}
