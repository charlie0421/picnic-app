import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/youtube_service.dart';

void main() {
  group('YouTubeContentService', () {
    group('싱글톤 패턴', () {
      test('factory 생성자는 항상 동일한 인스턴스를 반환한다', () {
        final instance1 = YouTubeContentService();
        final instance2 = YouTubeContentService();
        expect(identical(instance1, instance2), isTrue);
      });

      test('인스턴스는 YouTubeContentService 타입이다', () {
        final instance = YouTubeContentService();
        expect(instance, isA<YouTubeContentService>());
      });
    });

    group('클래스 구조', () {
      late YouTubeContentService service;

      setUp(() {
        service = YouTubeContentService();
      });

      test('fetchYoutubeInfo 메서드가 존재한다', () {
        expect(service.fetchYoutubeInfo, isA<Function>());
      });
    });
  });

  group('VideoInfo', () {
    test('필수 파라미터로 VideoInfo 객체를 생성할 수 있다', () {
      final publishedAt = DateTime(2025, 1, 15);
      final videoInfo = VideoInfo(
        id: 'dQw4w9WgXcQ',
        title: '테스트 동영상',
        channelTitle: '테스트 채널',
        channelThumbnail: 'https://example.com/thumb.jpg',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        viewCount: 1000000,
        publishedAt: publishedAt,
      );

      expect(videoInfo.id, equals('dQw4w9WgXcQ'));
      expect(videoInfo.title, equals('테스트 동영상'));
      expect(videoInfo.channelTitle, equals('테스트 채널'));
      expect(videoInfo.channelThumbnail, equals('https://example.com/thumb.jpg'));
      expect(videoInfo.thumbnailUrl,
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'));
      expect(videoInfo.viewCount, equals(1000000));
      expect(videoInfo.publishedAt, equals(publishedAt));
    });

    test('viewCount가 0인 VideoInfo를 생성할 수 있다', () {
      final videoInfo = VideoInfo(
        id: '',
        title: '',
        channelTitle: '',
        channelThumbnail: '',
        thumbnailUrl: '',
        viewCount: 0,
        publishedAt: DateTime.now(),
      );
      expect(videoInfo.viewCount, equals(0));
    });

    test('빈 문자열로 VideoInfo를 생성할 수 있다', () {
      final videoInfo = VideoInfo(
        id: '',
        title: '',
        channelTitle: '',
        channelThumbnail: '',
        thumbnailUrl: '',
        viewCount: 0,
        publishedAt: DateTime.now(),
      );
      expect(videoInfo.id, isEmpty);
      expect(videoInfo.title, isEmpty);
      expect(videoInfo.channelTitle, isEmpty);
    });
  });
}
