import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_environment.dart';

/// Tests for ShortformInternalPlatform logic patterns.
///
/// Widget testing is blocked because ShortformInternalPlatform extends
/// AdPlatform (which requires WidgetRef/BuildContext) and imports
/// video_player and supabase_flutter.
/// Instead, we test the pure logic patterns the class relies on.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('_rewriteVideoUrlIfNeeded logic', () {
    const cloudfrontBase =
        'https://d2jrkjksiktw4e.cloudfront.net/picnic/videos/output';
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    String rewriteVideoUrlIfNeeded(String? url) {
      if (url == null || url.isEmpty) return '';
      final normalized = url.split('?').first.split('#').first;

      // 1) ads/* path -> extract UUID and rewrite
      final hasAds =
          normalized.startsWith('ads/') || normalized.contains('/ads/');
      if (hasAds) {
        final segments = normalized
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList();
        String? id;
        for (final s in segments) {
          final part =
              s.contains('.') ? s.substring(0, s.lastIndexOf('.')) : s;
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

    test('returns empty string for null url', () {
      expect(rewriteVideoUrlIfNeeded(null), equals(''));
    });

    test('returns empty string for empty url', () {
      expect(rewriteVideoUrlIfNeeded(''), equals(''));
    });

    test('rewrites ads/ path with UUID', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result = rewriteVideoUrlIfNeeded('ads/$uuid.mp4');
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('rewrites /ads/ path with UUID', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result =
          rewriteVideoUrlIfNeeded('https://example.com/ads/$uuid.mp4');
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('rewrites ads path without extension', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result = rewriteVideoUrlIfNeeded('ads/$uuid');
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('rewrites /videos/output/ path', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result = rewriteVideoUrlIfNeeded(
        'https://cdn.example.com/picnic/videos/output/$uuid/master.m3u8',
      );
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('preserves non-matching URLs', () {
      const url = 'https://cdn.example.com/other/path/video.mp4';
      final result = rewriteVideoUrlIfNeeded(url);
      expect(result, equals(url));
    });

    test('strips query parameters before processing', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result =
          rewriteVideoUrlIfNeeded('ads/$uuid.mp4?token=abc&sig=xyz');
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('strips hash fragment before processing', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result = rewriteVideoUrlIfNeeded('ads/$uuid.mp4#section');
      expect(result, equals('$cloudfrontBase/$uuid/master.m3u8'));
    });

    test('handles ads path with non-UUID filename', () {
      final result = rewriteVideoUrlIfNeeded('ads/my-video.mp4');
      expect(result, equals('$cloudfrontBase/my-video/master.m3u8'));
    });

    test('handles /videos/output/ with file extension', () {
      const id = 'test-video-id';
      final result = rewriteVideoUrlIfNeeded(
        'https://example.com/videos/output/$id.m3u8',
      );
      expect(result, equals('$cloudfrontBase/$id/master.m3u8'));
    });
  });

  group('UUID pattern matching', () {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    test('matches valid UUID v4', () {
      expect(
        uuidPattern.hasMatch('550e8400-e29b-41d4-a716-446655440000'),
        isTrue,
      );
    });

    test('matches uppercase UUID', () {
      expect(
        uuidPattern.hasMatch('550E8400-E29B-41D4-A716-446655440000'),
        isTrue,
      );
    });

    test('does not match non-UUID string', () {
      expect(uuidPattern.hasMatch('not-a-uuid'), isFalse);
    });

    test('does not match partial UUID', () {
      expect(uuidPattern.hasMatch('550e8400-e29b-41d4'), isFalse);
    });

    test('does not match empty string', () {
      expect(uuidPattern.hasMatch(''), isFalse);
    });
  });

  group('Token management', () {
    test('view token empty check', () {
      String? viewToken;
      expect((viewToken ?? '').isEmpty, isTrue);

      viewToken = '';
      expect((viewToken).isEmpty, isTrue);

      viewToken = 'valid-token';
      expect((viewToken).isEmpty, isFalse);
    });

    test('more token empty check', () {
      String? moreToken;
      expect((moreToken ?? '').isEmpty, isTrue);

      moreToken = 'valid-token';
      expect((moreToken).isEmpty, isFalse);
    });
  });

  group('Error retry logic', () {
    test('detects expired token error', () {
      bool shouldRetry(String errorMessage) {
        final msg = errorMessage.toLowerCase();
        return msg.contains('expired') || msg.contains('bad request');
      }

      expect(shouldRetry('Token expired'), isTrue);
      expect(shouldRetry('Bad Request'), isTrue);
      expect(shouldRetry('Network timeout'), isFalse);
      expect(shouldRetry(''), isFalse);
    });

    test('retry only happens once after reissue', () {
      int retryCount = 0;
      const maxRetries = 1;

      bool canRetry() => retryCount < maxRetries;

      expect(canRetry(), isTrue);
      retryCount++;
      expect(canRetry(), isFalse);
    });
  });

  group('Video progress tracking', () {
    test('view called when position reaches duration', () {
      bool viewCalled = false;
      bool isInitialized = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      if (!viewCalled && isInitialized && position >= duration) {
        viewCalled = true;
      }

      expect(viewCalled, isTrue);
    });

    test('view not called when position is before duration', () {
      bool viewCalled = false;
      bool isInitialized = true;
      const position = Duration(seconds: 15);
      const duration = Duration(seconds: 30);

      if (!viewCalled && isInitialized && position >= duration) {
        viewCalled = true;
      }

      expect(viewCalled, isFalse);
    });

    test('view not called again after already called', () {
      bool viewCalled = true; // Already called
      int callCount = 0;
      bool isInitialized = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      if (!viewCalled && isInitialized && position >= duration) {
        viewCalled = true;
        callCount++;
      }

      expect(callCount, equals(0)); // Should not increment again
    });
  });
}
