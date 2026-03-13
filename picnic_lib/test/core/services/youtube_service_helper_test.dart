import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/youtube_service.dart';
import 'package:picnic_lib/core/services/youtube_service_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // extractVideoId
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.extractVideoId', () {
    test('extracts id from standard watch URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from watch URL with extra query params', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120&list=PLxyz'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from youtu.be short URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from youtu.be URL with query params', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://youtu.be/dQw4w9WgXcQ?t=30'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from embed URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://www.youtube.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from shorts URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from mobile youtube URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://m.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('returns null for non-YouTube URL', () {
      expect(
        YouTubeServiceHelper.extractVideoId('https://www.google.com'),
        isNull,
      );
    });

    test('returns null for empty string', () {
      expect(YouTubeServiceHelper.extractVideoId(''), isNull);
    });

    test('returns null for youtu.be with no path', () {
      expect(YouTubeServiceHelper.extractVideoId('https://youtu.be/'), isNull);
    });

    test('returns null for youtube.com with no v param on watch', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://www.youtube.com/watch?list=PLxyz'),
        isNull,
      );
    });

    test('returns null for plain text', () {
      expect(YouTubeServiceHelper.extractVideoId('not a url at all'), isNull);
    });

    test('extracts id from URL without www', () {
      expect(
        YouTubeServiceHelper.extractVideoId(
            'https://youtube.com/watch?v=abc123_-XYZ'),
        'abc123_-XYZ',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildThumbnailUrl
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.buildThumbnailUrl', () {
    test('builds hqdefault URL by default', () {
      expect(
        YouTubeServiceHelper.buildThumbnailUrl('abc123'),
        'https://img.youtube.com/vi/abc123/hqdefault.jpg',
      );
    });

    test('builds URL with custom quality', () {
      expect(
        YouTubeServiceHelper.buildThumbnailUrl('abc123',
            quality: 'maxresdefault'),
        'https://img.youtube.com/vi/abc123/maxresdefault.jpg',
      );
    });

    test('builds URL with mqdefault quality', () {
      expect(
        YouTubeServiceHelper.buildThumbnailUrl('abc123', quality: 'mqdefault'),
        'https://img.youtube.com/vi/abc123/mqdefault.jpg',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // selectBestThumbnail
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.selectBestThumbnail', () {
    test('selects maxres when available', () {
      final thumbs = {
        'maxres': {'url': 'https://maxres.jpg'},
        'high': {'url': 'https://high.jpg'},
        'default': {'url': 'https://default.jpg'},
      };
      expect(
        YouTubeServiceHelper.selectBestThumbnail(thumbs, 'vid1'),
        'https://maxres.jpg',
      );
    });

    test('falls back to standard when maxres missing', () {
      final thumbs = {
        'standard': {'url': 'https://standard.jpg'},
        'high': {'url': 'https://high.jpg'},
      };
      expect(
        YouTubeServiceHelper.selectBestThumbnail(thumbs, 'vid1'),
        'https://standard.jpg',
      );
    });

    test('falls back to high when standard missing', () {
      final thumbs = {
        'high': {'url': 'https://high.jpg'},
        'medium': {'url': 'https://medium.jpg'},
      };
      expect(
        YouTubeServiceHelper.selectBestThumbnail(thumbs, 'vid1'),
        'https://high.jpg',
      );
    });

    test('falls back to medium when high missing', () {
      final thumbs = {
        'medium': {'url': 'https://medium.jpg'},
      };
      expect(
        YouTubeServiceHelper.selectBestThumbnail(thumbs, 'vid1'),
        'https://medium.jpg',
      );
    });

    test('falls back to default when medium missing', () {
      final thumbs = {
        'default': {'url': 'https://default.jpg'},
      };
      expect(
        YouTubeServiceHelper.selectBestThumbnail(thumbs, 'vid1'),
        'https://default.jpg',
      );
    });

    test('falls back to constructed URL when thumbnails map is empty', () {
      expect(
        YouTubeServiceHelper.selectBestThumbnail({}, 'vid1'),
        'https://img.youtube.com/vi/vid1/hqdefault.jpg',
      );
    });

    test('falls back to constructed URL when thumbnails is null', () {
      expect(
        YouTubeServiceHelper.selectBestThumbnail(null, 'vid1'),
        'https://img.youtube.com/vi/vid1/hqdefault.jpg',
      );
    });

    test('uses custom fallbackQuality', () {
      expect(
        YouTubeServiceHelper.selectBestThumbnail(null, 'vid1',
            fallbackQuality: 'mqdefault'),
        'https://img.youtube.com/vi/vid1/mqdefault.jpg',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // extractChannelThumbnail
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.extractChannelThumbnail', () {
    test('extracts thumbnail from valid channel data', () {
      final data = {
        'items': [
          {
            'snippet': {
              'thumbnails': {
                'default': {'url': 'https://channel-thumb.jpg'}
              }
            }
          }
        ]
      };
      expect(
        YouTubeServiceHelper.extractChannelThumbnail(data),
        'https://channel-thumb.jpg',
      );
    });

    test('returns empty string when items is null', () {
      expect(
        YouTubeServiceHelper.extractChannelThumbnail({'items': null}),
        '',
      );
    });

    test('returns empty string when items is empty', () {
      expect(
        YouTubeServiceHelper.extractChannelThumbnail({'items': []}),
        '',
      );
    });

    test('returns empty string when no items key', () {
      expect(
        YouTubeServiceHelper.extractChannelThumbnail({}),
        '',
      );
    });

    test('returns empty string when nested path is missing', () {
      final data = {
        'items': [
          {'snippet': {}}
        ]
      };
      expect(
        YouTubeServiceHelper.extractChannelThumbnail(data),
        '',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // decodeHtmlEntities
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.decodeHtmlEntities', () {
    test('decodes &quot;', () {
      expect(
          YouTubeServiceHelper.decodeHtmlEntities('He said &quot;hello&quot;'),
          'He said "hello"');
    });

    test('decodes &amp;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('Tom &amp; Jerry'),
          'Tom & Jerry');
    });

    test('decodes &lt; and &gt;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('&lt;b&gt;bold&lt;/b&gt;'),
          '<b>bold</b>');
    });

    test('decodes &apos;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('it&apos;s'), "it's");
    });

    test('decodes &#39;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('it&#39;s'), "it's");
    });

    test('decodes &#x27;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('it&#x27;s'), "it's");
    });

    test('decodes &#x2F; (uppercase)', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('a&#x2F;b'), 'a/b');
    });

    test('decodes &#x2f; (lowercase)', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('a&#x2f;b'), 'a/b');
    });

    test('decodes &#47;', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities('a&#47;b'), 'a/b');
    });

    test('decodes &nbsp;', () {
      expect(
          YouTubeServiceHelper.decodeHtmlEntities('hello&nbsp;world'),
          'hello world');
    });

    test('handles text with no entities', () {
      expect(
          YouTubeServiceHelper.decodeHtmlEntities('plain text'), 'plain text');
    });

    test('handles empty string', () {
      expect(YouTubeServiceHelper.decodeHtmlEntities(''), '');
    });

    test('decodes multiple mixed entities', () {
      expect(
        YouTubeServiceHelper.decodeHtmlEntities(
            '&lt;a&gt;Tom &amp; Jerry&apos;s &quot;Show&quot;&lt;/a&gt;'),
        '<a>Tom & Jerry\'s "Show"</a>',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // createFallbackVideoInfo
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.createFallbackVideoInfo', () {
    test('creates fallback with valid YouTube URL', () {
      final info = YouTubeServiceHelper.createFallbackVideoInfo(
          'https://www.youtube.com/watch?v=abc123');
      expect(info.id, 'abc123');
      expect(info.title, 'YouTube Video');
      expect(info.channelTitle, 'Unknown Channel');
      expect(info.channelThumbnail, '');
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/abc123/hqdefault.jpg');
      expect(info.viewCount, 0);
    });

    test('creates fallback with non-YouTube URL', () {
      final info = YouTubeServiceHelper.createFallbackVideoInfo(
          'https://www.google.com');
      expect(info.id, '');
      expect(info.thumbnailUrl, '');
    });

    test('creates fallback with empty string', () {
      final info = YouTubeServiceHelper.createFallbackVideoInfo('');
      expect(info.id, '');
      expect(info.thumbnailUrl, '');
    });
  });

  // ---------------------------------------------------------------------------
  // parseWebApiResponse
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.parseWebApiResponse', () {
    test('parses complete response correctly', () {
      final data = {
        'videoId': 'vid123',
        'title': 'Test &amp; Title',
        'channelTitle': 'Channel &lt;Name&gt;',
        'channelThumbnail': 'https://ch-thumb.jpg',
        'viewCount': '12345',
        'publishedAt': '2024-01-15T10:30:00Z',
        'thumbnails': {
          'maxres': {'url': 'https://maxres.jpg'},
          'high': {'url': 'https://high.jpg'},
        },
      };

      final info = YouTubeServiceHelper.parseWebApiResponse(data, 'fallback');
      expect(info.id, 'vid123');
      expect(info.title, 'Test & Title');
      expect(info.channelTitle, 'Channel <Name>');
      expect(info.channelThumbnail, 'https://ch-thumb.jpg');
      expect(info.viewCount, 12345);
      expect(info.thumbnailUrl, 'https://maxres.jpg');
      expect(info.publishedAt, DateTime.utc(2024, 1, 15, 10, 30));
    });

    test('uses fallback videoId when not present in data', () {
      final info =
          YouTubeServiceHelper.parseWebApiResponse({}, 'myFallbackId');
      expect(info.id, 'myFallbackId');
    });

    test('handles missing fields gracefully', () {
      final info = YouTubeServiceHelper.parseWebApiResponse({}, 'vid1');
      expect(info.title, 'YouTube Video');
      expect(info.channelTitle, 'Unknown Channel');
      expect(info.channelThumbnail, '');
      expect(info.viewCount, 0);
      // Falls back to constructed thumbnail with mqdefault
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/mqdefault.jpg');
    });

    test('handles viewCount as integer', () {
      final info = YouTubeServiceHelper.parseWebApiResponse(
          {'viewCount': 999}, 'vid1');
      expect(info.viewCount, 999);
    });

    test('handles invalid viewCount string', () {
      final info = YouTubeServiceHelper.parseWebApiResponse(
          {'viewCount': 'not_a_number'}, 'vid1');
      expect(info.viewCount, 0);
    });

    test('handles invalid publishedAt string', () {
      final info = YouTubeServiceHelper.parseWebApiResponse(
          {'publishedAt': 'not_a_date'}, 'vid1');
      expect(info.publishedAt, DateTime.utc(1970));
    });
  });

  // ---------------------------------------------------------------------------
  // parseNativeVideoData
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.parseNativeVideoData', () {
    test('parses complete native video data', () {
      final video = {
        'snippet': {
          'title': 'Native &amp; Title',
          'channelTitle': 'Channel',
          'publishedAt': '2023-06-01T12:00:00Z',
          'thumbnails': {
            'maxres': {'url': 'https://maxres-native.jpg'},
            'high': {'url': 'https://high-native.jpg'},
          },
        },
        'statistics': {
          'viewCount': '67890',
        },
      };

      final info = YouTubeServiceHelper.parseNativeVideoData(
          video, 'nativeVid', 'https://ch.jpg');
      expect(info.id, 'nativeVid');
      expect(info.title, 'Native & Title');
      expect(info.channelTitle, 'Channel');
      expect(info.channelThumbnail, 'https://ch.jpg');
      expect(info.viewCount, 67890);
      expect(info.thumbnailUrl, 'https://maxres-native.jpg');
      expect(info.publishedAt, DateTime.utc(2023, 6, 1, 12));
    });

    test('falls back to high thumbnail when maxres missing', () {
      final video = {
        'snippet': {
          'title': 'Title',
          'channelTitle': 'Ch',
          'publishedAt': '2023-01-01T00:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://high-only.jpg'},
          },
        },
        'statistics': {'viewCount': '0'},
      };

      final info =
          YouTubeServiceHelper.parseNativeVideoData(video, 'vid1', '');
      expect(info.thumbnailUrl, 'https://high-only.jpg');
    });

    test('falls back to constructed thumbnail when none available', () {
      final video = {
        'snippet': {
          'title': 'Title',
          'channelTitle': 'Ch',
          'publishedAt': '2023-01-01T00:00:00Z',
          'thumbnails': <String, dynamic>{},
        },
        'statistics': {'viewCount': '0'},
      };

      final info =
          YouTubeServiceHelper.parseNativeVideoData(video, 'vid1', '');
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/hqdefault.jpg');
    });

    test('handles null snippet and statistics', () {
      final info = YouTubeServiceHelper.parseNativeVideoData(
          <String, dynamic>{}, 'vid1', 'ch.jpg');
      expect(info.id, 'vid1');
      expect(info.title, '');
      expect(info.channelTitle, '');
      expect(info.channelThumbnail, 'ch.jpg');
      expect(info.viewCount, 0);
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/hqdefault.jpg');
    });
  });

  // ---------------------------------------------------------------------------
  // isYouTubeUrl
  // ---------------------------------------------------------------------------
  group('YouTubeServiceHelper.isYouTubeUrl', () {
    test('returns true for standard watch URL', () {
      expect(
        YouTubeServiceHelper.isYouTubeUrl(
            'https://www.youtube.com/watch?v=abc123'),
        isTrue,
      );
    });

    test('returns true for short URL', () {
      expect(
        YouTubeServiceHelper.isYouTubeUrl('https://youtu.be/abc123'),
        isTrue,
      );
    });

    test('returns true for embed URL', () {
      expect(
        YouTubeServiceHelper.isYouTubeUrl(
            'https://www.youtube.com/embed/abc123'),
        isTrue,
      );
    });

    test('returns true for shorts URL', () {
      expect(
        YouTubeServiceHelper.isYouTubeUrl(
            'https://www.youtube.com/shorts/abc123'),
        isTrue,
      );
    });

    test('returns false for non-YouTube URL', () {
      expect(
        YouTubeServiceHelper.isYouTubeUrl('https://www.google.com'),
        isFalse,
      );
    });

    test('returns false for empty string', () {
      expect(YouTubeServiceHelper.isYouTubeUrl(''), isFalse);
    });

    test('returns false for plain text', () {
      expect(YouTubeServiceHelper.isYouTubeUrl('hello world'), isFalse);
    });
  });
}
