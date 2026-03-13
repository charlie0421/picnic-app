import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';

/// Extended tests for LinkService covering additional edge cases
/// for normalizeUrl, isValidUrl, and LinkPreview model.
void main() {
  late LinkService service;

  setUp(() {
    service = LinkService();
  });

  group('LinkService.normalizeUrl edge cases', () {
    test('trims whitespace', () {
      final result = service.normalizeUrl('  https://example.com  ');
      expect(result, 'https://example.com');
    });

    test('adds https:// when no protocol', () {
      final result = service.normalizeUrl('example.com');
      expect(result, 'https://example.com');
    });

    test('preserves https://', () {
      final result = service.normalizeUrl('https://example.com');
      expect(result, 'https://example.com');
    });

    test('preserves http://', () {
      final result = service.normalizeUrl('http://example.com');
      expect(result, 'http://example.com');
    });

    test('preserves ftp://', () {
      final result = service.normalizeUrl('ftp://files.example.com');
      expect(result, 'ftp://files.example.com');
    });

    test('handles URL with path', () {
      final result = service.normalizeUrl('example.com/page/subpage');
      expect(result, 'https://example.com/page/subpage');
    });

    test('handles URL with query parameters', () {
      final result = service.normalizeUrl('example.com?q=search&lang=ko');
      expect(result, 'https://example.com?q=search&lang=ko');
    });

    test('handles URL with port', () {
      final result = service.normalizeUrl('localhost:3000');
      expect(result, 'https://localhost:3000');
    });

    test('handles empty string', () {
      final result = service.normalizeUrl('');
      expect(result, 'https://');
    });

    test('handles URL with fragment', () {
      final result = service.normalizeUrl('example.com#section');
      expect(result, 'https://example.com#section');
    });
  });

  group('LinkService.isValidUrl', () {
    test('returns true for valid https URL', () {
      expect(service.isValidUrl('https://example.com'), isTrue);
    });

    test('returns true for valid http URL', () {
      expect(service.isValidUrl('http://example.com'), isTrue);
    });

    test('returns false for empty string', () {
      expect(service.isValidUrl(''), isFalse);
    });

    test('returns false for plain text', () {
      expect(service.isValidUrl('not a url'), isFalse);
    });

    test('returns true for URL with path', () {
      expect(service.isValidUrl('https://example.com/path/to/page'), isTrue);
    });

    test('returns true for URL with query', () {
      expect(service.isValidUrl('https://example.com?key=value'), isTrue);
    });

    test('returns true for just protocol (has empty authority)', () {
      // Uri.parse('https://').hasAuthority returns true
      expect(service.isValidUrl('https://'), isTrue);
    });

    test('returns true for URL with port', () {
      expect(service.isValidUrl('https://localhost:8080'), isTrue);
    });
  });

  group('LinkPreview.fromJson edge cases', () {
    test('uses imageUrl key as fallback for image', () {
      final preview = LinkPreview.fromJson({
        'title': 'Test',
        'description': 'Desc',
        'imageUrl': 'https://example.com/img.jpg',
      }, 'https://example.com');

      expect(preview.imageUrl, 'https://example.com/img.jpg');
    });

    test('prefers image over imageUrl', () {
      final preview = LinkPreview.fromJson({
        'title': 'Test',
        'description': 'Desc',
        'image': 'https://example.com/primary.jpg',
        'imageUrl': 'https://example.com/fallback.jpg',
      }, 'https://example.com');

      expect(preview.imageUrl, 'https://example.com/primary.jpg');
    });

    test('uses host as title when title is null', () {
      final preview = LinkPreview.fromJson(
        {'description': 'Some desc'},
        'https://flutter.dev/docs',
      );

      expect(preview.title, 'flutter.dev');
    });

    test('uses default description when null', () {
      final preview = LinkPreview.fromJson(
        {'title': 'Test'},
        'https://example.com',
      );

      expect(preview.description, 'Click to visit the website');
    });

    test('handles all null fields', () {
      final preview = LinkPreview.fromJson({}, 'https://example.com');

      expect(preview.title, 'example.com');
      expect(preview.description, 'Click to visit the website');
      expect(preview.imageUrl, isNull);
      expect(preview.favicon, isNull);
      expect(preview.url, 'https://example.com');
    });
  });

  group('LinkPreview.fallback', () {
    test('creates with host as title', () {
      final preview = LinkPreview.fallback('https://flutter.dev');
      expect(preview.title, 'flutter.dev');
    });

    test('creates with default description', () {
      final preview = LinkPreview.fallback('https://example.com');
      expect(preview.description, 'Click to visit the website');
    });

    test('imageUrl is null in fallback', () {
      final preview = LinkPreview.fallback('https://example.com');
      expect(preview.imageUrl, isNull);
    });

    test('preserves original URL', () {
      const url = 'https://example.com/some/path?q=test';
      final preview = LinkPreview.fallback(url);
      expect(preview.url, url);
    });
  });

  group('LinkPreview.toJson', () {
    test('includes all fields', () {
      final preview = LinkPreview(
        title: 'T',
        description: 'D',
        imageUrl: 'img',
        favicon: 'fav',
        url: 'u',
      );

      final json = preview.toJson();
      expect(json.length, 5);
      expect(json.keys, containsAll(['title', 'description', 'imageUrl', 'favicon', 'url']));
    });

    test('handles null imageUrl and favicon', () {
      final preview = LinkPreview(
        title: 'T',
        description: 'D',
        url: 'u',
      );

      final json = preview.toJson();
      expect(json['imageUrl'], isNull);
      expect(json['favicon'], isNull);
    });
  });

  group('LinkPreviewException', () {
    test('toString includes status code when present', () {
      final e = LinkPreviewException('Failed', statusCode: 403);
      expect(e.toString(), contains('403'));
      expect(e.toString(), contains('Failed'));
    });

    test('toString excludes Status when no status code', () {
      final e = LinkPreviewException('Network issue');
      final str = e.toString();
      expect(str, contains('Network issue'));
      expect(str, isNot(contains('Status')));
    });

    test('message is accessible', () {
      final e = LinkPreviewException('test message', statusCode: 500);
      expect(e.message, 'test message');
      expect(e.statusCode, 500);
    });
  });
}
