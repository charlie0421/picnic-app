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

  group('selectBestThumbnail', () {
    test('returns maxres when available', () {
      final thumbnails = {
        'maxres': {'url': 'https://maxres.jpg'},
        'high': {'url': 'https://high.jpg'},
        'medium': {'url': 'https://medium.jpg'},
        'default': {'url': 'https://default.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://maxres.jpg',
      );
    });

    test('falls back to standard when maxres missing', () {
      final thumbnails = {
        'standard': {'url': 'https://standard.jpg'},
        'high': {'url': 'https://high.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://standard.jpg',
      );
    });

    test('falls back to high when maxres and standard missing', () {
      final thumbnails = {
        'high': {'url': 'https://high.jpg'},
        'medium': {'url': 'https://medium.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://high.jpg',
      );
    });

    test('falls back to medium when higher qualities missing', () {
      final thumbnails = {
        'medium': {'url': 'https://medium.jpg'},
        'default': {'url': 'https://default.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://medium.jpg',
      );
    });

    test('falls back to default when only default available', () {
      final thumbnails = {
        'default': {'url': 'https://default.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://default.jpg',
      );
    });

    test('returns fallback URL when thumbnails is null', () {
      expect(
        YouTubeContentService.selectBestThumbnail(null, 'vid1'),
        'https://img.youtube.com/vi/vid1/hqdefault.jpg',
      );
    });

    test('returns fallback URL when thumbnails map is empty', () {
      expect(
        YouTubeContentService.selectBestThumbnail({}, 'vid1'),
        'https://img.youtube.com/vi/vid1/hqdefault.jpg',
      );
    });

    test('uses custom fallbackQuality parameter', () {
      expect(
        YouTubeContentService.selectBestThumbnail(
          null,
          'vid1',
          fallbackQuality: 'mqdefault',
        ),
        'https://img.youtube.com/vi/vid1/mqdefault.jpg',
      );
    });

    test('handles thumbnail entry with null url', () {
      final thumbnails = {
        'maxres': {'url': null},
        'high': {'url': 'https://high.jpg'},
      };
      expect(
        YouTubeContentService.selectBestThumbnail(thumbnails, 'vid1'),
        'https://high.jpg',
      );
    });
  });

  group('extractChannelThumbnail', () {
    test('extracts thumbnail from valid channel data', () {
      final channelData = {
        'items': [
          {
            'snippet': {
              'thumbnails': {
                'default': {'url': 'https://channel-thumb.jpg'},
              },
            },
          },
        ],
      };
      expect(
        YouTubeContentService.extractChannelThumbnail(channelData),
        'https://channel-thumb.jpg',
      );
    });

    test('returns empty string when items is null', () {
      expect(
        YouTubeContentService.extractChannelThumbnail({}),
        '',
      );
    });

    test('returns empty string when items is empty list', () {
      expect(
        YouTubeContentService.extractChannelThumbnail({'items': []}),
        '',
      );
    });

    test('returns empty string when snippet is missing', () {
      final channelData = {
        'items': [{}],
      };
      expect(
        YouTubeContentService.extractChannelThumbnail(channelData),
        '',
      );
    });

    test('returns empty string when thumbnails is missing', () {
      final channelData = {
        'items': [
          {'snippet': {}},
        ],
      };
      expect(
        YouTubeContentService.extractChannelThumbnail(channelData),
        '',
      );
    });
  });

  group('parseWebApiResponse', () {
    test('parses complete response correctly', () {
      final data = {
        'videoId': 'abc123',
        'title': 'Test &amp; Video',
        'channelTitle': 'My &lt;Channel&gt;',
        'channelThumbnail': 'https://ch-thumb.jpg',
        'viewCount': '12345',
        'publishedAt': '2024-06-15T10:30:00Z',
        'thumbnails': {
          'maxres': {'url': 'https://maxres.jpg'},
          'high': {'url': 'https://high.jpg'},
        },
      };
      final info = service.parseWebApiResponse(data, 'abc123');
      expect(info.id, 'abc123');
      expect(info.title, 'Test & Video');
      expect(info.channelTitle, 'My <Channel>');
      expect(info.channelThumbnail, 'https://ch-thumb.jpg');
      expect(info.thumbnailUrl, 'https://maxres.jpg');
      expect(info.viewCount, 12345);
      expect(info.publishedAt, DateTime.utc(2024, 6, 15, 10, 30));
    });

    test('uses videoId param when videoId missing in data', () {
      final data = <String, dynamic>{
        'title': 'Video',
        'channelTitle': 'Channel',
      };
      final info = service.parseWebApiResponse(data, 'fallback_id');
      expect(info.id, 'fallback_id');
    });

    test('uses default title when title missing', () {
      final data = <String, dynamic>{};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.title, 'YouTube Video');
    });

    test('uses default channel title when missing', () {
      final data = <String, dynamic>{};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.channelTitle, 'Unknown Channel');
    });

    test('uses empty string when channelThumbnail missing', () {
      final data = <String, dynamic>{};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.channelThumbnail, '');
    });

    test('defaults viewCount to 0 when missing', () {
      final data = <String, dynamic>{};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.viewCount, 0);
    });

    test('handles viewCount as integer', () {
      final data = <String, dynamic>{'viewCount': 999};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.viewCount, 999);
    });

    test('handles viewCount as string', () {
      final data = <String, dynamic>{'viewCount': '42'};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.viewCount, 42);
    });

    test('defaults viewCount to 0 for non-numeric string', () {
      final data = <String, dynamic>{'viewCount': 'not_a_number'};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.viewCount, 0);
    });

    test('uses fallback thumbnail when thumbnails null', () {
      final data = <String, dynamic>{};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/mqdefault.jpg');
    });

    test('selects high quality thumbnail when maxres and standard missing', () {
      final data = {
        'thumbnails': {
          'high': {'url': 'https://high.jpg'},
          'medium': {'url': 'https://medium.jpg'},
        },
      };
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(info.thumbnailUrl, 'https://high.jpg');
    });

    test('handles invalid publishedAt gracefully', () {
      final data = <String, dynamic>{'publishedAt': 'not-a-date'};
      final info = service.parseWebApiResponse(data, 'vid1');
      // Should default to DateTime.now() - just check it's a recent date
      expect(
        info.publishedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('handles empty publishedAt string', () {
      final data = <String, dynamic>{'publishedAt': ''};
      final info = service.parseWebApiResponse(data, 'vid1');
      expect(
        info.publishedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });
  });

  group('parseNativeVideoData', () {
    test('parses complete video data correctly', () {
      final video = {
        'snippet': {
          'title': 'Native &amp; Video',
          'channelTitle': 'Native Channel',
          'publishedAt': '2024-01-20T08:00:00Z',
          'thumbnails': {
            'maxres': {'url': 'https://maxres-native.jpg'},
            'high': {'url': 'https://high-native.jpg'},
          },
        },
        'statistics': {
          'viewCount': '999999',
        },
      };
      final info =
          service.parseNativeVideoData(video, 'native1', 'https://ch.jpg');
      expect(info.id, 'native1');
      expect(info.title, 'Native & Video');
      expect(info.channelTitle, 'Native Channel');
      expect(info.channelThumbnail, 'https://ch.jpg');
      expect(info.thumbnailUrl, 'https://maxres-native.jpg');
      expect(info.viewCount, 999999);
      expect(info.publishedAt, DateTime.utc(2024, 1, 20, 8));
    });

    test('falls back to high thumbnail when maxres missing', () {
      final video = {
        'snippet': {
          'title': 'Video',
          'channelTitle': 'Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://high-native.jpg'},
          },
        },
        'statistics': {'viewCount': '0'},
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(info.thumbnailUrl, 'https://high-native.jpg');
    });

    test('falls back to default thumbnail URL when no thumbnails', () {
      final video = {
        'snippet': {
          'title': 'Video',
          'channelTitle': 'Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
          'thumbnails': <String, dynamic>{},
        },
        'statistics': {'viewCount': '0'},
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/hqdefault.jpg');
    });

    test('handles missing snippet gracefully', () {
      final video = <String, dynamic>{
        'statistics': {'viewCount': '100'},
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(info.title, '');
      expect(info.channelTitle, '');
      expect(info.thumbnailUrl,
          'https://img.youtube.com/vi/vid1/hqdefault.jpg');
    });

    test('handles missing statistics gracefully', () {
      final video = {
        'snippet': {
          'title': 'Video',
          'channelTitle': 'Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(info.viewCount, 0);
    });

    test('handles null viewCount in statistics', () {
      final video = {
        'snippet': {
          'title': 'Video',
          'channelTitle': 'Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        'statistics': <String, dynamic>{},
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(info.viewCount, 0);
    });

    test('handles invalid publishedAt in snippet', () {
      final video = {
        'snippet': {
          'title': 'Video',
          'channelTitle': 'Channel',
          'publishedAt': 'bad-date',
        },
        'statistics': {'viewCount': '0'},
      };
      final info = service.parseNativeVideoData(video, 'vid1', '');
      expect(
        info.publishedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });
  });
}
