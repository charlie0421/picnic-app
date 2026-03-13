import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_video_player_page.dart';

/// Tests for QnaVideoPlayerPage production code.
///
/// Widget rendering requires video_player and chewie native plugins.
/// We test importable production code: constructor.
void main() {
  group('QnaVideoPlayerPage widget', () {
    test('can be constructed with videoUrl', () {
      const page = QnaVideoPlayerPage(
        videoUrl: 'https://example.com/video.mp4',
      );
      expect(page, isA<QnaVideoPlayerPage>());
      expect(page.videoUrl, 'https://example.com/video.mp4');
    });

    test('with key can be constructed', () {
      const page = QnaVideoPlayerPage(
        key: ValueKey('video_player'),
        videoUrl: 'https://example.com/video.mp4',
      );
      expect(page.key, equals(const ValueKey('video_player')));
    });

    test('different videoUrls', () {
      const p1 = QnaVideoPlayerPage(videoUrl: 'https://a.com/1.mp4');
      const p2 = QnaVideoPlayerPage(videoUrl: 'https://b.com/2.mp4');
      expect(p1.videoUrl, isNot(p2.videoUrl));
    });
  });
}
