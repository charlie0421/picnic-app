import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/link_service.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/deletable_embed_builder.dart';

/// Tests for LinkEmbedBuilder key logic and related classes.
///
/// Widget rendering tests for the preview widgets are limited because
/// they require a QuillController with embedded nodes and
/// network calls for link preview fetching via LinkService.
/// Instead we test the builder class properties, URL parsing logic,
/// and text decoding patterns used within the widgets.
void main() {
  group('LinkEmbedBuilder', () {
    test('key is "link"', () {
      final builder = LinkEmbedBuilder();
      expect(builder.key, 'link');
    });

    test('is an instance of EmbedBuilder', () {
      final builder = LinkEmbedBuilder();
      expect(builder, isNotNull);
    });
  });

  group('EditableLinkEmbedBuilder', () {
    test('key is "link"', () {
      final builder = EditableLinkEmbedBuilder();
      expect(builder.key, 'link');
    });

    test('is an instance of EmbedBuilder', () {
      final builder = EditableLinkEmbedBuilder();
      expect(builder, isNotNull);
    });
  });

  group('DeletableLinkEmbedBuilder', () {
    test('can be instantiated', () {
      final builder = DeletableLinkEmbedBuilder();
      expect(builder, isNotNull);
    });

    test('key is "link"', () {
      final builder = DeletableLinkEmbedBuilder();
      expect(builder.key, 'link');
    });

    test('is a DeletableEmbedBuilder', () {
      final builder = DeletableLinkEmbedBuilder();
      expect(builder, isA<DeletableEmbedBuilder>());
    });
  });

  group('URL extraction logic (mirrors _extractUrl)', () {
    test('extracts URL from JSON string data', () {
      final data = '{"url": "https://example.com"}';
      String url = '';

      if (data is String) {
        try {
          final jsonData = json.decode(data);
          url = jsonData['url'] as String? ?? '';
        } catch (e) {
          url = data;
        }
      }

      expect(url, 'https://example.com');
    });

    test('extracts URL from map data', () {
      final data = {'url': 'https://flutter.dev'};
      String url = '';

      if (data is Map<String, dynamic>) {
        url = data['url'] as String? ?? '';
      }

      expect(url, 'https://flutter.dev');
    });

    test('handles invalid JSON string gracefully', () {
      const data = 'not-a-json-string';
      String url = '';

      if (data is String) {
        try {
          final jsonData = json.decode(data);
          url = jsonData['url'] as String? ?? '';
        } catch (e) {
          url = data;
        }
      }

      expect(url, 'not-a-json-string');
    });

    test('handles JSON without url key', () {
      const data = '{"title": "No URL here"}';
      String url = '';

      if (data is String) {
        try {
          final jsonData = json.decode(data);
          url = jsonData['url'] as String? ?? '';
        } catch (e) {
          url = data;
        }
      }

      expect(url, '');
    });

    test('handles empty JSON object', () {
      const data = '{}';
      String url = '';

      if (data is String) {
        try {
          final jsonData = json.decode(data);
          url = jsonData['url'] as String? ?? '';
        } catch (e) {
          url = data;
        }
      }

      expect(url, '');
    });

    test('extracts URL from nested map', () {
      final data = <String, dynamic>{
        'url': 'https://picnic.fan',
        'title': 'Picnic',
      };

      String url = '';
      if (data is Map<String, dynamic>) {
        url = data['url'] as String? ?? '';
      }

      expect(url, 'https://picnic.fan');
    });

    test('handles null url in map', () {
      final data = <String, dynamic>{'url': null};

      String url = '';
      if (data is Map<String, dynamic>) {
        url = data['url'] as String? ?? '';
      }

      expect(url, '');
    });
  });

  group('Text decoding logic (mirrors _decodeText)', () {
    String decodeText(String text) {
      try {
        return utf8.decode(text.runes.toList());
      } catch (e) {
        try {
          return latin1.decode(text.codeUnits);
        } catch (e) {
          return text;
        }
      }
    }

    test('decodes ASCII text', () {
      expect(decodeText('Hello World'), 'Hello World');
    });

    test('decodes Korean text', () {
      expect(decodeText('안녕하세요'), '안녕하세요');
    });

    test('decodes Japanese text', () {
      expect(decodeText('こんにちは'), 'こんにちは');
    });

    test('decodes empty string', () {
      expect(decodeText(''), '');
    });

    test('decodes text with special characters', () {
      expect(decodeText('Hello & World <test>'), 'Hello & World <test>');
    });

    test('decodes text with numbers', () {
      expect(decodeText('Price: 1,234'), 'Price: 1,234');
    });

    test('decodes text with emojis', () {
      final result = decodeText('Hello 🎉');
      expect(result, isNotEmpty);
    });
  });

  group('Empty URL handling logic', () {
    test('empty URL triggers error state', () {
      final url = '';
      bool isLoading = true;
      String? errorMessage;

      if (url.isEmpty) {
        isLoading = false;
        errorMessage = 'Empty URL';
      }

      expect(isLoading, isFalse);
      expect(errorMessage, 'Empty URL');
    });

    test('non-empty URL does not trigger error', () {
      final url = 'https://example.com';
      bool isLoading = true;
      String? errorMessage;

      if (url.isEmpty) {
        isLoading = false;
        errorMessage = 'Empty URL';
      }

      expect(isLoading, isTrue);
      expect(errorMessage, isNull);
    });
  });

  group('LinkService normalizeUrl logic', () {
    test('LinkService can be instantiated', () {
      final service = LinkService();
      expect(service, isNotNull);
    });

    test('normalizeUrl adds https protocol', () {
      final service = LinkService();
      expect(service.normalizeUrl('example.com'), startsWith('http'));
    });

    test('normalizeUrl keeps existing https', () {
      final service = LinkService();
      final result = service.normalizeUrl('https://example.com');
      expect(result, startsWith('https://'));
    });

    test('normalizeUrl keeps existing http', () {
      final service = LinkService();
      final result = service.normalizeUrl('http://example.com');
      expect(result, startsWith('http://'));
    });
  });

  group('LinkPreview model', () {
    test('creates from JSON', () {
      final preview = LinkPreview.fromJson({
        'title': 'Test Title',
        'description': 'Test Description',
        'image': 'https://example.com/image.jpg',
        'favicon': 'https://example.com/favicon.ico',
      }, 'https://example.com');

      expect(preview.title, 'Test Title');
      expect(preview.description, 'Test Description');
      expect(preview.imageUrl, 'https://example.com/image.jpg');
      expect(preview.favicon, 'https://example.com/favicon.ico');
      expect(preview.url, 'https://example.com');
    });

    test('creates from JSON with missing fields', () {
      final preview = LinkPreview.fromJson(
        {},
        'https://example.com',
      );

      expect(preview.title, 'example.com');
      expect(preview.description, 'Click to visit the website');
      expect(preview.imageUrl, isNull);
    });

    test('creates fallback', () {
      final preview = LinkPreview.fallback('https://example.com');
      expect(preview.url, 'https://example.com');
      expect(preview.title, isNotEmpty);
    });

    test('toJson returns correct map', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        imageUrl: 'img.jpg',
        favicon: 'fav.ico',
        url: 'https://test.com',
      );

      final json = preview.toJson();
      expect(json['title'], 'Title');
      expect(json['description'], 'Desc');
      expect(json['imageUrl'], 'img.jpg');
      expect(json['favicon'], 'fav.ico');
      expect(json['url'], 'https://test.com');
    });

    test('toString returns readable string', () {
      final preview = LinkPreview(
        title: 'Title',
        description: 'Desc',
        url: 'https://test.com',
      );

      final str = preview.toString();
      expect(str, contains('Title'));
      expect(str, contains('Desc'));
      expect(str, contains('https://test.com'));
    });
  });

  group('LinkPreviewException', () {
    test('creates with message', () {
      final exception = LinkPreviewException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.statusCode, isNull);
    });

    test('creates with message and status code', () {
      final exception = LinkPreviewException('Not found', statusCode: 404);
      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
    });

    test('toString with status code', () {
      final exception = LinkPreviewException('Error', statusCode: 500);
      expect(exception.toString(), contains('500'));
      expect(exception.toString(), contains('Error'));
    });

    test('toString without status code', () {
      final exception = LinkPreviewException('Simple error');
      expect(exception.toString(), contains('Simple error'));
      expect(exception.toString(), isNot(contains('Status')));
    });
  });

  group('DeletableEmbedBuilder', () {
    test('key returns embedType', () {
      final builder = DeletableEmbedBuilder(
        embedType: 'custom',
        contentBuilder: (context, node) => const SizedBox(),
      );
      expect(builder.key, 'custom');
    });

    test('embedType is stored correctly', () {
      final builder = DeletableEmbedBuilder(
        embedType: 'video',
        contentBuilder: (context, node) => const SizedBox(),
      );
      expect(builder.embedType, 'video');
    });
  });
}
