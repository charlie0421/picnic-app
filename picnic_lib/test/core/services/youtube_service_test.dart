import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/youtube_service.dart';

void main() {
  late YouTubeContentService service;

  setUp(() {
    service = YouTubeContentService();
  });

  group('extractVideoId', () {
    test('extracts id from standard youtube url', () {
      expect(service.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });

    test('extracts id from short url', () {
      expect(service.extractVideoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });

    test('extracts id from embed url', () {
      expect(service.extractVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });

    test('extracts id from shorts url', () {
      expect(service.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });

    test('returns null for non-youtube url', () {
      expect(service.extractVideoId('https://example.com/video'), isNull);
    });

    test('returns null for empty url', () {
      expect(service.extractVideoId(''), isNull);
    });

    test('extracts id with extra query params', () {
      expect(service.extractVideoId('https://www.youtube.com/watch?v=abc123&t=10'), 'abc123');
    });

    test('handles youtube.com without www', () {
      expect(service.extractVideoId('https://youtube.com/watch?v=abc123'), 'abc123');
    });

    test('returns null for youtube channel url', () {
      expect(service.extractVideoId('https://www.youtube.com/channel/UC123'), isNull);
    });
  });

  group('decodeHtmlEntities', () {
    test('decodes &quot;', () {
      expect(service.decodeHtmlEntities('&quot;hello&quot;'), '"hello"');
    });

    test('decodes &amp;', () {
      expect(service.decodeHtmlEntities('A &amp; B'), 'A & B');
    });

    test('decodes &lt; and &gt;', () {
      expect(service.decodeHtmlEntities('&lt;div&gt;'), '<div>');
    });

    test('decodes &apos;', () {
      expect(service.decodeHtmlEntities('it&apos;s'), "it's");
    });

    test('decodes &#39;', () {
      expect(service.decodeHtmlEntities('it&#39;s'), "it's");
    });

    test('decodes &#x27;', () {
      expect(service.decodeHtmlEntities('it&#x27;s'), "it's");
    });

    test('decodes &#x2F; and &#x2f;', () {
      expect(service.decodeHtmlEntities('a&#x2F;b'), 'a/b');
      expect(service.decodeHtmlEntities('a&#x2f;b'), 'a/b');
    });

    test('decodes &#47;', () {
      expect(service.decodeHtmlEntities('a&#47;b'), 'a/b');
    });

    test('decodes &nbsp;', () {
      expect(service.decodeHtmlEntities('hello&nbsp;world'), 'hello world');
    });

    test('handles text without entities', () {
      expect(service.decodeHtmlEntities('plain text'), 'plain text');
    });

    test('handles multiple entities', () {
      expect(service.decodeHtmlEntities('&lt;a href=&quot;url&quot;&gt;'), '<a href="url">');
    });

    test('handles empty string', () {
      expect(service.decodeHtmlEntities(''), '');
    });
  });

  group('createFallbackVideoInfo', () {
    test('creates fallback for valid youtube url', () {
      final info = service.createFallbackVideoInfo('https://www.youtube.com/watch?v=abc123');
      expect(info.id, 'abc123');
      expect(info.title, 'YouTube Video');
      expect(info.channelTitle, 'Unknown Channel');
      expect(info.channelThumbnail, '');
      expect(info.thumbnailUrl, contains('abc123'));
      expect(info.viewCount, 0);
    });

    test('creates fallback for invalid url', () {
      final info = service.createFallbackVideoInfo('https://example.com');
      expect(info.id, '');
      expect(info.thumbnailUrl, '');
    });

    test('creates fallback for short url', () {
      final info = service.createFallbackVideoInfo('https://youtu.be/xyz789');
      expect(info.id, 'xyz789');
      expect(info.thumbnailUrl, contains('xyz789'));
    });
  });

  group('VideoInfo', () {
    test('constructor creates valid instance', () {
      final info = VideoInfo(
        id: 'test',
        title: 'Test Video',
        channelTitle: 'Test Channel',
        channelThumbnail: 'thumb.jpg',
        thumbnailUrl: 'video_thumb.jpg',
        viewCount: 1000,
        publishedAt: DateTime(2024, 1, 1),
      );
      expect(info.id, 'test');
      expect(info.title, 'Test Video');
      expect(info.channelTitle, 'Test Channel');
      expect(info.viewCount, 1000);
    });
  });
}
