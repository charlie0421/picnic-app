import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';

void main() {
  group('LinkPreviewException', () {
    test('toString with statusCode', () {
      final ex = LinkPreviewException('test error', statusCode: 404);
      expect(ex.toString(), equals('LinkPreviewException: test error (Status: 404)'));
    });

    test('toString without statusCode', () {
      final ex = LinkPreviewException('test error');
      expect(ex.toString(), equals('LinkPreviewException: test error'));
    });

    test('message 접근', () {
      final ex = LinkPreviewException('네트워크 오류', statusCode: 500);
      expect(ex.message, equals('네트워크 오류'));
      expect(ex.statusCode, equals(500));
    });
  });

  group('LinkPreview', () {
    test('fromJson 기본', () {
      final json = {
        'title': 'Test Title',
        'description': 'Test Description',
        'image': 'https://example.com/img.jpg',
        'favicon': 'https://example.com/fav.ico',
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.title, equals('Test Title'));
      expect(preview.description, equals('Test Description'));
      expect(preview.imageUrl, equals('https://example.com/img.jpg'));
      expect(preview.favicon, equals('https://example.com/fav.ico'));
      expect(preview.url, equals('https://example.com'));
    });

    test('fromJson null title은 host로 fallback', () {
      final json = <String, dynamic>{
        'title': null,
        'description': null,
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com/page');
      expect(preview.title, equals('example.com'));
      expect(preview.description, equals('Click to visit the website'));
    });

    test('fromJson imageUrl key 우선순위', () {
      final json = {
        'title': 'T',
        'description': 'D',
        'imageUrl': 'https://example.com/img2.jpg',
      };
      final preview = LinkPreview.fromJson(json, 'https://example.com');
      expect(preview.imageUrl, equals('https://example.com/img2.jpg'));
    });

    test('fallback factory', () {
      final preview = LinkPreview.fallback('https://example.com/test');
      expect(preview.title, equals('example.com'));
      expect(preview.description, equals('Click to visit the website'));
      expect(preview.url, equals('https://example.com/test'));
      expect(preview.imageUrl, isNull);
      expect(preview.favicon, isNull);
    });

    test('toJson', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        imageUrl: 'img.jpg',
        favicon: 'fav.ico',
        url: 'https://example.com',
      );
      final json = preview.toJson();
      expect(json['title'], equals('Title'));
      expect(json['description'], equals('Desc'));
      expect(json['imageUrl'], equals('img.jpg'));
      expect(json['favicon'], equals('fav.ico'));
      expect(json['url'], equals('https://example.com'));
    });

    test('toString', () {
      final preview = LinkPreview(
        title: 'T',
        description: 'D',
        url: 'https://example.com',
      );
      expect(preview.toString(), contains('LinkPreview'));
      expect(preview.toString(), contains('T'));
    });
  });

  group('LinkService', () {
    test('싱글톤 패턴', () {
      final a = LinkService();
      final b = LinkService();
      expect(identical(a, b), isTrue);
    });

    test('normalizeUrl http 프로토콜 없으면 https 추가', () {
      final service = LinkService();
      expect(service.normalizeUrl('example.com'), equals('https://example.com'));
    });

    test('normalizeUrl 이미 프로토콜 있으면 그대로', () {
      final service = LinkService();
      expect(service.normalizeUrl('http://example.com'), equals('http://example.com'));
      expect(service.normalizeUrl('https://example.com'), equals('https://example.com'));
    });

    test('normalizeUrl 공백 제거', () {
      final service = LinkService();
      expect(service.normalizeUrl('  example.com  '), equals('https://example.com'));
    });

    test('isValidUrl 유효한 URL', () {
      final service = LinkService();
      expect(service.isValidUrl('https://example.com'), isTrue);
      expect(service.isValidUrl('http://localhost:3000'), isTrue);
    });

    test('isValidUrl 유효하지 않은 URL', () {
      final service = LinkService();
      expect(service.isValidUrl(''), isFalse);
      expect(service.isValidUrl('not a url'), isFalse);
    });
  });
}
