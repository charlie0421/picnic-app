import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';

/// Tests for VideoThumbnail widgets production code.
///
/// Widget rendering requires video_thumbnail native plugin which is not
/// available in test environment. We test constructor and properties.
void main() {
  group('VideoThumbnailFromUrl widget', () {
    test('can be constructed with required parameters', () {
      const widget = VideoThumbnailFromUrl(
        videoUrl: 'https://example.com/video.mp4',
      );
      expect(widget, isA<VideoThumbnailFromUrl>());
      expect(widget.videoUrl, 'https://example.com/video.mp4');
    });

    test('default values', () {
      const widget = VideoThumbnailFromUrl(
        videoUrl: 'https://example.com/video.mp4',
      );
      expect(widget.width, isNull);
      expect(widget.height, isNull);
      expect(widget.fit, BoxFit.cover);
      expect(widget.loading, isNull);
    });

    test('can be constructed with all optional parameters', () {
      const widget = VideoThumbnailFromUrl(
        videoUrl: 'https://example.com/video.mp4',
        width: 160,
        height: 90,
        fit: BoxFit.contain,
        loading: CircularProgressIndicator(),
      );
      expect(widget.width, 160);
      expect(widget.height, 90);
      expect(widget.fit, BoxFit.contain);
      expect(widget.loading, isA<CircularProgressIndicator>());
    });

    test('with key can be constructed', () {
      const widget = VideoThumbnailFromUrl(
        key: ValueKey('video_thumb'),
        videoUrl: 'https://example.com/video.mp4',
      );
      expect(widget.key, equals(const ValueKey('video_thumb')));
    });
  });

  group('VideoThumbnailFromFile widget', () {
    test('can be constructed with required parameters', () {
      final widget = VideoThumbnailFromFile(
        file: File('/tmp/test_video.mp4'),
      );
      expect(widget, isA<VideoThumbnailFromFile>());
      expect(widget.filePath, '/tmp/test_video.mp4');
    });

    test('default values', () {
      final widget = VideoThumbnailFromFile(
        file: File('/tmp/video.mp4'),
      );
      expect(widget.width, isNull);
      expect(widget.height, isNull);
      expect(widget.fit, BoxFit.cover);
      expect(widget.loading, isNull);
    });

    test('can be constructed with all optional parameters', () {
      final widget = VideoThumbnailFromFile(
        file: File('/tmp/video.mp4'),
        width: 200,
        height: 150,
        fit: BoxFit.fill,
        loading: const Text('Loading...'),
      );
      expect(widget.width, 200);
      expect(widget.height, 150);
      expect(widget.fit, BoxFit.fill);
      expect(widget.loading, isA<Text>());
    });

    test('filePath is derived from File', () {
      final file = File('/path/to/my_video.mp4');
      final widget = VideoThumbnailFromFile(file: file);
      expect(widget.filePath, file.path);
    });
  });
}
