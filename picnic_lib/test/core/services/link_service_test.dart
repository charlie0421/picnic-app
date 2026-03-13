import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';

void main() {
  late LinkService service;

  setUp(() {
    service = LinkService();
  });

  group('normalizeUrl', () {
    test('adds https:// when no protocol', () {
      expect(service.normalizeUrl('example.com'), 'https://example.com');
    });

    test('preserves https:// when present', () {
      expect(service.normalizeUrl('https://example.com'), 'https://example.com');
    });

    test('preserves http:// when present', () {
      expect(service.normalizeUrl('http://example.com'), 'http://example.com');
    });

    test('trims whitespace', () {
      expect(service.normalizeUrl('  example.com  '), 'https://example.com');
    });

    test('handles url with path', () {
      expect(service.normalizeUrl('example.com/path'), 'https://example.com/path');
    });

    test('handles url with query string', () {
      expect(service.normalizeUrl('example.com?q=test'), 'https://example.com?q=test');
    });

    test('handles ftp protocol', () {
      expect(service.normalizeUrl('ftp://files.example.com'), 'ftp://files.example.com');
    });
  });

  group('isValidUrl', () {
    test('returns true for valid https url', () {
      expect(service.isValidUrl('https://example.com'), isTrue);
    });

    test('returns true for valid http url', () {
      expect(service.isValidUrl('http://example.com'), isTrue);
    });

    test('returns true for url with path', () {
      expect(service.isValidUrl('https://example.com/path/to/page'), isTrue);
    });

    test('returns true for url with query', () {
      expect(service.isValidUrl('https://example.com?q=hello'), isTrue);
    });

    test('returns false for empty string', () {
      expect(service.isValidUrl(''), isFalse);
    });

    test('returns false for plain text', () {
      expect(service.isValidUrl('not a url'), isFalse);
    });

    test('returns true for url with port', () {
      expect(service.isValidUrl('https://example.com:8080'), isTrue);
    });

    test('returns true for subdomain', () {
      expect(service.isValidUrl('https://sub.example.com'), isTrue);
    });
  });

  group('LinkPreview', () {
    test('fromJson creates correct instance', () {
      final json = {
        'title': 'Test Title',
        'description': 'Test Description',
        'image': 'https://img.com/test.jpg',
        'favicon': 'https://example.com/favicon.ico',
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.title, 'Test Title');
      expect(preview.description, 'Test Description');
      expect(preview.imageUrl, 'https://img.com/test.jpg');
      expect(preview.favicon, 'https://example.com/favicon.ico');
      expect(preview.url, 'https://example.com');
    });

    test('fromJson uses host as title fallback', () {
      final json = <String, dynamic>{};
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.title, 'example.com');
    });

    test('fromJson uses default description', () {
      final json = <String, dynamic>{};
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.description, 'Click to visit the website');
    });

    test('fromJson handles imageUrl key', () {
      final json = <String, dynamic>{
        'imageUrl': 'https://img.com/test.jpg',
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.imageUrl, 'https://img.com/test.jpg');
    });

    test('fallback creates minimal preview', () {
      final preview = LinkPreview.fallback('https://example.com');
      expect(preview.title, 'example.com');
      expect(preview.description, 'Click to visit the website');
      expect(preview.url, 'https://example.com');
      expect(preview.imageUrl, isNull);
    });

    test('toJson returns correct map', () {
      final preview = LinkPreview(
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.jpg',
        favicon: 'fav.ico',
        url: 'https://test.com',
      );
      final json = preview.toJson();
      expect(json['title'], 'Test');
      expect(json['description'], 'Desc');
      expect(json['imageUrl'], 'img.jpg');
      expect(json['favicon'], 'fav.ico');
      expect(json['url'], 'https://test.com');
    });

    test('toString returns formatted string', () {
      final preview = LinkPreview(
        title: 'Test',
        description: 'Desc',
        url: 'https://test.com',
      );
      final str = preview.toString();
      expect(str, contains('Test'));
      expect(str, contains('Desc'));
      expect(str, contains('https://test.com'));
    });
  });

  group('LinkPreviewException', () {
    test('toString includes message', () {
      final ex = LinkPreviewException('test error');
      expect(ex.toString(), contains('test error'));
    });

    test('toString includes status code when present', () {
      final ex = LinkPreviewException('test error', statusCode: 404);
      expect(ex.toString(), contains('404'));
    });

    test('toString omits status code when null', () {
      final ex = LinkPreviewException('test error');
      expect(ex.toString(), isNot(contains('Status')));
    });

    test('message property is accessible', () {
      final ex = LinkPreviewException('my error');
      expect(ex.message, 'my error');
    });

    test('statusCode property is accessible', () {
      final ex = LinkPreviewException('error', statusCode: 500);
      expect(ex.statusCode, 500);
    });
  });
}
