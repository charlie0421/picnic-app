import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';
import 'package:picnic_lib/core/services/link_service_helper.dart';

void main() {
  group('LinkServiceHelper.normalizeUrl', () {
    test('adds https:// when no protocol is present', () {
      expect(LinkServiceHelper.normalizeUrl('example.com'), 'https://example.com');
    });

    test('preserves https:// when already present', () {
      expect(LinkServiceHelper.normalizeUrl('https://example.com'), 'https://example.com');
    });

    test('preserves http:// when already present', () {
      expect(LinkServiceHelper.normalizeUrl('http://example.com'), 'http://example.com');
    });

    test('trims leading and trailing whitespace', () {
      expect(LinkServiceHelper.normalizeUrl('  example.com  '), 'https://example.com');
    });

    test('handles url with path', () {
      expect(LinkServiceHelper.normalizeUrl('example.com/path/to/page'), 'https://example.com/path/to/page');
    });

    test('handles url with query string', () {
      expect(LinkServiceHelper.normalizeUrl('example.com?q=test&lang=en'), 'https://example.com?q=test&lang=en');
    });

    test('handles ftp protocol', () {
      expect(LinkServiceHelper.normalizeUrl('ftp://files.example.com'), 'ftp://files.example.com');
    });

    test('handles url with fragment', () {
      expect(LinkServiceHelper.normalizeUrl('example.com#section'), 'https://example.com#section');
    });

    test('handles url with port', () {
      expect(LinkServiceHelper.normalizeUrl('example.com:8080'), 'https://example.com:8080');
    });

    test('handles empty string after trim', () {
      expect(LinkServiceHelper.normalizeUrl('   '), 'https://');
    });
  });

  group('LinkServiceHelper.isValidUrl', () {
    test('returns true for valid https url', () {
      expect(LinkServiceHelper.isValidUrl('https://example.com'), isTrue);
    });

    test('returns true for valid http url', () {
      expect(LinkServiceHelper.isValidUrl('http://example.com'), isTrue);
    });

    test('returns true for url with path', () {
      expect(LinkServiceHelper.isValidUrl('https://example.com/path'), isTrue);
    });

    test('returns true for url with query parameters', () {
      expect(LinkServiceHelper.isValidUrl('https://example.com?q=hello&page=1'), isTrue);
    });

    test('returns true for url with port', () {
      expect(LinkServiceHelper.isValidUrl('https://example.com:8080'), isTrue);
    });

    test('returns true for url with subdomain', () {
      expect(LinkServiceHelper.isValidUrl('https://sub.example.com'), isTrue);
    });

    test('returns false for empty string', () {
      expect(LinkServiceHelper.isValidUrl(''), isFalse);
    });

    test('returns false for plain text without protocol', () {
      expect(LinkServiceHelper.isValidUrl('not a url'), isFalse);
    });

    test('returns true for just a protocol with empty authority', () {
      // Uri.parse('https://').hasAuthority returns true (empty authority)
      expect(LinkServiceHelper.isValidUrl('https://'), isTrue);
    });

    test('returns true for IP-based url', () {
      expect(LinkServiceHelper.isValidUrl('http://192.168.1.1'), isTrue);
    });

    test('returns true for localhost', () {
      expect(LinkServiceHelper.isValidUrl('http://localhost:3000'), isTrue);
    });
  });

  group('LinkServiceHelper.buildHeaders', () {
    test('returns map with correct Content-Type', () {
      final headers = LinkServiceHelper.buildHeaders(anonKey: 'test-key');
      expect(headers['Content-Type'], 'application/json');
    });

    test('returns map with Bearer authorization', () {
      final headers = LinkServiceHelper.buildHeaders(anonKey: 'test-key');
      expect(headers['Authorization'], 'Bearer test-key');
    });

    test('returns map with apikey header', () {
      final headers = LinkServiceHelper.buildHeaders(anonKey: 'test-key');
      expect(headers['apikey'], 'test-key');
    });

    test('returns exactly 3 headers', () {
      final headers = LinkServiceHelper.buildHeaders(anonKey: 'key');
      expect(headers.length, 3);
    });

    test('handles empty anon key', () {
      final headers = LinkServiceHelper.buildHeaders(anonKey: '');
      expect(headers['Authorization'], 'Bearer ');
      expect(headers['apikey'], '');
    });
  });

  group('LinkServiceHelper.buildEndpointUrl', () {
    test('appends link-preview function path', () {
      expect(
        LinkServiceHelper.buildEndpointUrl('https://abc.supabase.co'),
        'https://abc.supabase.co/functions/v1/link-preview',
      );
    });

    test('handles base URL without trailing slash', () {
      expect(
        LinkServiceHelper.buildEndpointUrl('https://abc.supabase.co'),
        'https://abc.supabase.co/functions/v1/link-preview',
      );
    });

    test('handles base URL with trailing slash produces double slash', () {
      // This tests current behavior - trailing slash in input produces double slash
      expect(
        LinkServiceHelper.buildEndpointUrl('https://abc.supabase.co/'),
        'https://abc.supabase.co//functions/v1/link-preview',
      );
    });
  });

  group('LinkServiceHelper.validateStatusCode', () {
    test('does not throw for 200', () {
      expect(() => LinkServiceHelper.validateStatusCode(200), returnsNormally);
    });

    test('throws LinkPreviewException with statusCode 401 for auth failure', () {
      expect(
        () => LinkServiceHelper.validateStatusCode(401),
        throwsA(
          isA<LinkPreviewException>()
              .having((e) => e.message, 'message', 'Authentication failed')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws LinkPreviewException for 500 server error', () {
      expect(
        () => LinkServiceHelper.validateStatusCode(500),
        throwsA(
          isA<LinkPreviewException>()
              .having((e) => e.message, 'message', 'Failed to fetch preview')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws LinkPreviewException for 404 not found', () {
      expect(
        () => LinkServiceHelper.validateStatusCode(404),
        throwsA(
          isA<LinkPreviewException>()
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws LinkPreviewException for 403 forbidden', () {
      expect(
        () => LinkServiceHelper.validateStatusCode(403),
        throwsA(
          isA<LinkPreviewException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws for 201 (only 200 is success)', () {
      expect(
        () => LinkServiceHelper.validateStatusCode(201),
        throwsA(isA<LinkPreviewException>()),
      );
    });
  });

  group('LinkServiceHelper.parseResponseData', () {
    test('parses standard response data', () {
      final data = {
        'title': 'My Page',
        'description': 'A description',
        'image': 'https://img.com/pic.jpg',
        'favicon': 'https://example.com/fav.ico',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
      );
      expect(preview.title, 'My Page');
      expect(preview.description, 'A description');
      expect(preview.imageUrl, 'https://img.com/pic.jpg');
      expect(preview.favicon, 'https://example.com/fav.ico');
      expect(preview.url, 'https://example.com');
    });

    test('uses host as title fallback when title is null', () {
      final preview = LinkServiceHelper.parseResponseData(
        <String, dynamic>{},
        'https://example.com',
      );
      expect(preview.title, 'example.com');
    });

    test('uses default description when description is null', () {
      final preview = LinkServiceHelper.parseResponseData(
        <String, dynamic>{},
        'https://example.com',
      );
      expect(preview.description, 'Click to visit the website');
    });

    test('returns fallback data when handleFallback is true and error+fallback present', () {
      final data = {
        'error': 'some error',
        'fallback': {
          'title': 'Fallback Title',
          'description': 'Fallback Desc',
        },
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
        handleFallback: true,
      );
      expect(preview.title, 'Fallback Title');
      expect(preview.description, 'Fallback Desc');
    });

    test('ignores fallback when handleFallback is false even if error+fallback present', () {
      final data = {
        'error': 'some error',
        'fallback': {
          'title': 'Fallback Title',
          'description': 'Fallback Desc',
        },
        'title': 'Main Title',
        'description': 'Main Desc',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
        handleFallback: false,
      );
      expect(preview.title, 'Main Title');
      expect(preview.description, 'Main Desc');
    });

    test('does not use fallback when only error is present (no fallback key)', () {
      final data = {
        'error': 'some error',
        'title': 'Normal Title',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
        handleFallback: true,
      );
      expect(preview.title, 'Normal Title');
    });

    test('does not use fallback when only fallback key is present (no error key)', () {
      final data = {
        'fallback': {'title': 'Fallback'},
        'title': 'Normal Title',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
        handleFallback: true,
      );
      expect(preview.title, 'Normal Title');
    });

    test('handles imageUrl key in response', () {
      final data = <String, dynamic>{
        'imageUrl': 'https://img.com/pic.jpg',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
      );
      expect(preview.imageUrl, 'https://img.com/pic.jpg');
    });

    test('prefers image key over imageUrl key', () {
      final data = <String, dynamic>{
        'image': 'https://img.com/image.jpg',
        'imageUrl': 'https://img.com/imageUrl.jpg',
      };
      final preview = LinkServiceHelper.parseResponseData(
        data,
        'https://example.com',
      );
      expect(preview.imageUrl, 'https://img.com/image.jpg');
    });
  });

  group('LinkServiceHelper.wrapException', () {
    test('returns same exception if already LinkPreviewException', () {
      final original = LinkPreviewException('original', statusCode: 404);
      final wrapped = LinkServiceHelper.wrapException(original);
      expect(identical(wrapped, original), isTrue);
    });

    test('wraps generic exception as LinkPreviewException', () {
      final wrapped = LinkServiceHelper.wrapException(Exception('generic error'));
      expect(wrapped, isA<LinkPreviewException>());
      expect(wrapped.message, contains('generic error'));
    });

    test('wraps string error as LinkPreviewException', () {
      final wrapped = LinkServiceHelper.wrapException('string error');
      expect(wrapped, isA<LinkPreviewException>());
      expect(wrapped.message, 'string error');
    });

    test('wraps FormatException as LinkPreviewException', () {
      final wrapped = LinkServiceHelper.wrapException(const FormatException('bad format'));
      expect(wrapped, isA<LinkPreviewException>());
      expect(wrapped.message, contains('bad format'));
    });

    test('wrapped exception has null statusCode', () {
      final wrapped = LinkServiceHelper.wrapException(Exception('test'));
      expect(wrapped.statusCode, isNull);
    });
  });
}
