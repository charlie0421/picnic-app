import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';

void main() {
  group('VideoInfo', () {
    test('필수 파라미터로 생성', () {
      const video = VideoInfo(
        id: 1,
        videoId: 'abc123',
        videoUrl: 'https://youtube.com/watch?v=abc123',
        title: {'ko': '뮤비', 'en': 'MV'},
        thumbnailUrl: 'https://img.youtube.com/vi/abc123/0.jpg',
        channelTitle: 'HYBE',
        channelId: 'channel-1',
        channelThumbnail: 'https://example.com/channel.jpg',
      );
      expect(video.id, equals(1));
      expect(video.videoId, equals('abc123'));
      expect(video.title['ko'], equals('뮤비'));
      expect(video.createdAt, isNull);
    });

    test('createdAt 포함 생성', () {
      final now = DateTime.now();
      final video = VideoInfo(
        id: 1,
        videoId: 'v1',
        videoUrl: 'url',
        title: const {'ko': '제목'},
        thumbnailUrl: 'thumb',
        channelTitle: 'ch',
        channelId: 'ch-1',
        channelThumbnail: 'ch-thumb',
        createdAt: now,
      );
      expect(video.createdAt, equals(now));
    });
  });
}
