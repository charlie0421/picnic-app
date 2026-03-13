import 'package:flutter_test/flutter_test.dart';

/// Tests for the URL rewriting logic from [ShortformInternalPlatform].
/// The rewriteVideoUrlIfNeeded method is pure logic that transforms video URLs
/// to CloudFront HLS master.m3u8 URLs.
///
/// Since instantiating ShortformInternalPlatform requires Flutter widget
/// dependencies (WidgetRef, BuildContext, AnimationController), we replicate
/// the pure logic here for unit testing.

void main() {
  const cloudfrontBase =
      'https://d2jrkjksiktw4e.cloudfront.net/picnic/videos/output';
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String rewriteVideoUrlIfNeeded(String? url) {
    if (url == null || url.isEmpty) return '';
    final normalized = url.split('?').first.split('#').first;

    // 1) ads/* path -> extract UUID and rewrite to CloudFront master.m3u8
    final hasAds =
        normalized.startsWith('ads/') || normalized.contains('/ads/');
    if (hasAds) {
      final segments =
          normalized.split('/').where((s) => s.isNotEmpty).toList();
      String? id;
      for (final s in segments) {
        final part = s.contains('.') ? s.substring(0, s.lastIndexOf('.')) : s;
        if (uuidPattern.hasMatch(part)) {
          id = part;
          break;
        }
      }
      id ??= () {
        final last = segments.isNotEmpty ? segments.last : '';
        return last.contains('.')
            ? last.substring(0, last.lastIndexOf('.'))
            : last;
      }();
      if (id.isEmpty) return url;
      return '$cloudfrontBase/$id/master.m3u8';
    }

    // 2) /videos/output/* path
    final pathOnly = () {
      final uri = Uri.tryParse(normalized);
      return uri?.path.isNotEmpty == true ? uri!.path : normalized;
    }();
    if (pathOnly.contains(RegExp(r'/videos/output/'))) {
      final segs = pathOnly.split('/').where((s) => s.isNotEmpty).toList();
      final idx = segs.indexWhere((s) => s == 'videos');
      if (idx != -1 && idx + 2 < segs.length && segs[idx + 1] == 'output') {
        var idSeg = segs[idx + 2];
        idSeg = idSeg.contains('.')
            ? idSeg.substring(0, idSeg.lastIndexOf('.'))
            : idSeg;
        if (idSeg.isNotEmpty) {
          return '$cloudfrontBase/$idSeg/master.m3u8';
        }
      }
    }

    return url;
  }

  group('rewriteVideoUrlIfNeeded', () {
    test('returns empty string for null url', () {
      expect(rewriteVideoUrlIfNeeded(null), '');
    });

    test('returns empty string for empty url', () {
      expect(rewriteVideoUrlIfNeeded(''), '');
    });

    test('returns original URL for non-ads, non-videos/output path', () {
      const url = 'https://example.com/some/random/path.mp4';
      expect(rewriteVideoUrlIfNeeded(url), url);
    });

    test('rewrites ads/ path with UUID to CloudFront HLS', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url = 'ads/$uuid.mp4';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });

    test('rewrites /ads/ path with UUID to CloudFront HLS', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url = 'https://storage.example.com/ads/$uuid.mp4';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });

    test('rewrites ads/ path with UUID without extension', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url = 'ads/$uuid';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });

    test('strips query parameters before processing ads/ path', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url = 'ads/$uuid.mp4?token=abc123';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });

    test('strips hash fragment before processing ads/ path', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url = 'ads/$uuid.mp4#section1';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });

    test('uses last segment as fallback ID for ads/ path without UUID', () {
      const url = 'ads/some-video-id.mp4';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/some-video-id/master.m3u8',
      );
    });

    test('rewrites /videos/output/ path to CloudFront HLS', () {
      const url =
          'https://storage.example.com/picnic/videos/output/my-video-id/master.m3u8';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/my-video-id/master.m3u8',
      );
    });

    test('rewrites /videos/output/ path with file extension', () {
      const url =
          'https://storage.example.com/videos/output/video123.mp4';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/video123/master.m3u8',
      );
    });

    test('rewrites /videos/output/ path with UUID', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const url =
          'https://storage.example.com/videos/output/$uuid/master.m3u8';
      expect(
        rewriteVideoUrlIfNeeded(url),
        '$cloudfrontBase/$uuid/master.m3u8',
      );
    });
  });
}
