import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';

void main() {
  group('LinkPreviewException', () {
    test('toString without statusCode', () {
      final e = LinkPreviewException('test error');
      expect(e.toString(), 'LinkPreviewException: test error');
      expect(e.message, 'test error');
      expect(e.statusCode, isNull);
    });

    test('toString with statusCode', () {
      final e = LinkPreviewException('auth failed', statusCode: 401);
      expect(e.toString(), 'LinkPreviewException: auth failed (Status: 401)');
      expect(e.statusCode, 401);
    });
  });

  group('LinkPreview', () {
    test('constructor with all fields', () {
      final preview = LinkPreview(
        title: 'Test Title',
        description: 'Test Description',
        imageUrl: 'https://example.com/img.png',
        favicon: 'https://example.com/favicon.ico',
        url: 'https://example.com',
      );
      expect(preview.title, 'Test Title');
      expect(preview.description, 'Test Description');
      expect(preview.imageUrl, 'https://example.com/img.png');
      expect(preview.favicon, 'https://example.com/favicon.ico');
      expect(preview.url, 'https://example.com');
    });

    test('constructor with minimal fields', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        url: 'https://example.com',
      );
      expect(preview.imageUrl, isNull);
      expect(preview.favicon, isNull);
    });

    test('toJson contains all fields', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        imageUrl: 'img.png',
        favicon: 'fav.ico',
        url: 'https://example.com',
      );
      final json = preview.toJson();
      expect(json['title'], 'Title');
      expect(json['description'], 'Desc');
      expect(json['imageUrl'], 'img.png');
      expect(json['favicon'], 'fav.ico');
      expect(json['url'], 'https://example.com');
    });

    test('toString contains title and url', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        url: 'https://example.com',
      );
      final str = preview.toString();
      expect(str, contains('Title'));
      expect(str, contains('https://example.com'));
    });

    test('fromJson with all fields', () {
      final json = {
        'title': 'Test',
        'description': 'Desc',
        'image': 'img.png',
        'favicon': 'fav.ico',
      };
      final preview =
          LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.title, 'Test');
      expect(preview.description, 'Desc');
      expect(preview.imageUrl, 'img.png');
      expect(preview.favicon, 'fav.ico');
      expect(preview.url, 'https://example.com');
    });

    test('fromJson with imageUrl key', () {
      final json = {
        'title': 'Test',
        'description': 'Desc',
        'imageUrl': 'img2.png',
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.imageUrl, 'img2.png');
    });

    test('fromJson with missing title uses host', () {
      final json = <String, dynamic>{'description': 'Desc'};
      final preview =
          LinkPreview.fromJson(json, 'https://example.com/page');
      expect(preview.title, 'example.com');
    });

    test('fromJson with missing description uses default', () {
      final json = <String, dynamic>{'title': 'Test'};
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.description, 'Click to visit the website');
    });

    test('fallback creates preview from URL', () {
      final preview = LinkPreview.fallback('https://google.com/search');
      expect(preview.title, 'google.com');
      expect(preview.description, 'Click to visit the website');
      expect(preview.url, 'https://google.com/search');
      expect(preview.imageUrl, isNull);
    });
  });

  group('LinkService', () {
    late LinkService service;

    setUp(() {
      service = LinkService();
    });

    group('normalizeUrl', () {
      test('adds https if no protocol', () {
        expect(service.normalizeUrl('google.com'), 'https://google.com');
      });

      test('preserves existing https', () {
        expect(
          service.normalizeUrl('https://google.com'),
          'https://google.com',
        );
      });

      test('preserves existing http', () {
        expect(
          service.normalizeUrl('http://google.com'),
          'http://google.com',
        );
      });

      test('trims whitespace', () {
        expect(
          service.normalizeUrl('  google.com  '),
          'https://google.com',
        );
      });
    });

    group('isValidUrl', () {
      test('valid https URL', () {
        expect(service.isValidUrl('https://google.com'), isTrue);
      });

      test('valid http URL', () {
        expect(service.isValidUrl('http://example.com'), isTrue);
      });

      test('URL without protocol is invalid (no authority)', () {
        // Uri.parse('google.com') doesn't have authority
        expect(service.isValidUrl('google.com'), isFalse);
      });

      test('empty string is invalid', () {
        expect(service.isValidUrl(''), isFalse);
      });

      test('URL with path is valid', () {
        expect(service.isValidUrl('https://example.com/path/to/page'), isTrue);
      });

      test('URL with query params is valid', () {
        expect(service.isValidUrl('https://example.com?q=test'), isTrue);
      });
    });
  });
}
