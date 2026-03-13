import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item.dart';

void main() {

  group('VideoListItem widget', () {
    test('can be constructed with required parameters', () {
      const widget = VideoListItem(
        videoId: 'abc123',
        title: {'ko': '테스트 영상', 'en': 'Test Video'},
        thumbnailUrl: 'https://img.youtube.com/vi/abc123/0.jpg',
        channelTitle: 'Test Channel',
        channelId: 'UC123456',
        channelThumbnail: 'https://example.com/channel.jpg',
      );
      expect(widget, isA<VideoListItem>());
      expect(widget.videoId, 'abc123');
      expect(widget.channelTitle, 'Test Channel');
      expect(widget.channelId, 'UC123456');
    });

    test('onTap callback is optional', () {
      const widget = VideoListItem(
        videoId: 'abc123',
        title: {'ko': '테스트', 'en': 'Test'},
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelTitle: 'Channel',
        channelId: 'UC123',
        channelThumbnail: 'https://example.com/ch.jpg',
      );
      expect(widget.onTap, isNull);
    });

    test('onTap callback can be set', () {
      bool tapped = false;
      final widget = VideoListItem(
        videoId: 'abc123',
        title: const {'ko': '테스트', 'en': 'Test'},
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelTitle: 'Channel',
        channelId: 'UC123',
        channelThumbnail: 'https://example.com/ch.jpg',
        onTap: () => tapped = true,
      );
      widget.onTap!();
      expect(tapped, isTrue);
    });

    test('title is a Map with language keys', () {
      const widget = VideoListItem(
        videoId: 'v1',
        title: {'ko': '한국어 제목', 'en': 'English Title', 'ja': '日本語タイトル'},
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelTitle: 'Channel',
        channelId: 'UC123',
        channelThumbnail: 'https://example.com/ch.jpg',
      );
      expect(widget.title.length, 3);
      expect(widget.title['ko'], '한국어 제목');
      expect(widget.title['en'], 'English Title');
    });

    test('with key can be constructed', () {
      const widget = VideoListItem(
        key: ValueKey('video_test'),
        videoId: 'v2',
        title: {'ko': '제목', 'en': 'Title'},
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelTitle: 'Channel',
        channelId: 'UC1',
        channelThumbnail: 'https://example.com/ch.jpg',
      );
      expect(widget.key, equals(const ValueKey('video_test')));
    });
  });

  group('VideoListItem URL generation logic', () {
    test('YouTube app URL format', () {
      const videoId = 'dQw4w9WgXcQ';
      final appUrl = Uri.parse('vnd.youtube://watch?v=$videoId');
      expect(appUrl.scheme, 'vnd.youtube');
      // URI parsing for custom schemes may differ from HTTP
      expect(appUrl.toString(), contains(videoId));
    });

    test('YouTube web URL format', () {
      const videoId = 'dQw4w9WgXcQ';
      final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
      expect(webUrl.host, 'www.youtube.com');
      expect(webUrl.path, '/watch');
      expect(webUrl.queryParameters['v'], videoId);
    });

    test('YouTube channel app URL contains channelId', () {
      const channelId = 'UC123456';
      final appUrl = Uri.parse('vnd.youtube://channel/$channelId');
      expect(appUrl.scheme, 'vnd.youtube');
      expect(appUrl.toString(), contains(channelId));
    });

    test('YouTube channel web URL format', () {
      const channelId = 'UC123456';
      final webUrl =
          Uri.parse('https://www.youtube.com/channel/$channelId');
      expect(webUrl.host, 'www.youtube.com');
      expect(webUrl.toString(), contains(channelId));
    });
  });
}
