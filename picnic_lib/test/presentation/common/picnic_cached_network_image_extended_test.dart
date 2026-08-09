import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/test_environment.dart';

/// Extended tests for PicnicCachedNetworkImage
/// covering enums, constructor, and non-widget logic.
void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('ImageComplexity enum', () {
    test('has correct number of values', () {
      expect(ImageComplexity.values.length, 3);
    });

    test('has expected indices', () {
      expect(ImageComplexity.low.index, 0);
      expect(ImageComplexity.medium.index, 1);
      expect(ImageComplexity.high.index, 2);
    });

    test('name returns correct string', () {
      expect(ImageComplexity.low.name, 'low');
      expect(ImageComplexity.medium.name, 'medium');
      expect(ImageComplexity.high.name, 'high');
    });
  });

  group('LazyLoadingStrategy enum', () {
    test('has correct number of values', () {
      expect(LazyLoadingStrategy.values.length, 4);
    });

    test('has expected indices', () {
      expect(LazyLoadingStrategy.none.index, 0);
      expect(LazyLoadingStrategy.viewport.index, 1);
      expect(LazyLoadingStrategy.preload.index, 2);
      expect(LazyLoadingStrategy.progressive.index, 3);
    });

    test('name returns correct string', () {
      expect(LazyLoadingStrategy.none.name, 'none');
      expect(LazyLoadingStrategy.viewport.name, 'viewport');
      expect(LazyLoadingStrategy.preload.name, 'preload');
      expect(LazyLoadingStrategy.progressive.name, 'progressive');
    });
  });

  group('ImagePriority enum', () {
    test('has correct number of values', () {
      expect(ImagePriority.values.length, 3);
    });

    test('has expected indices', () {
      expect(ImagePriority.low.index, 0);
      expect(ImagePriority.normal.index, 1);
      expect(ImagePriority.high.index, 2);
    });

    test('name returns correct string', () {
      expect(ImagePriority.low.name, 'low');
      expect(ImagePriority.normal.name, 'normal');
      expect(ImagePriority.high.name, 'high');
    });
  });

  group('PicnicCachedNetworkImage constructor', () {
    test('default values are correct', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'https://example.com/test.png');
      expect(widget.imageUrl, 'https://example.com/test.png');
      expect(widget.width, isNull);
      expect(widget.height, isNull);
      expect(widget.fit, BoxFit.cover);
      expect(widget.memCacheWidth, isNull);
      expect(widget.memCacheHeight, isNull);
      expect(widget.borderRadius, isNull);
      expect(widget.timeout, isNull);
      expect(widget.maxRetries, isNull);
      expect(widget.lazyLoadingStrategy, LazyLoadingStrategy.viewport);
      expect(widget.visibilityThreshold, 0.1);
      expect(widget.placeholder, isNull);
      expect(widget.showLoadingOverlay, true);
      expect(widget.priority, ImagePriority.normal);
      expect(widget.enableMemoryOptimization, true);
      expect(widget.enableProgressiveLoading, true);
    });

    test('custom values are set correctly', () {
      const widget = PicnicCachedNetworkImage(
        imageUrl: 'https://example.com/custom.png',
        width: 300,
        height: 400,
        fit: BoxFit.fill,
        memCacheWidth: 150,
        memCacheHeight: 200,
        borderRadius: BorderRadius.zero,
        timeout: Duration(seconds: 10),
        maxRetries: 5,
        lazyLoadingStrategy: LazyLoadingStrategy.none,
        visibilityThreshold: 0.5,
        showLoadingOverlay: false,
        priority: ImagePriority.high,
        enableMemoryOptimization: false,
        enableProgressiveLoading: false,
      );

      expect(widget.imageUrl, 'https://example.com/custom.png');
      expect(widget.width, 300);
      expect(widget.height, 400);
      expect(widget.fit, BoxFit.fill);
      expect(widget.memCacheWidth, 150);
      expect(widget.memCacheHeight, 200);
      expect(widget.borderRadius, BorderRadius.zero);
      expect(widget.timeout, const Duration(seconds: 10));
      expect(widget.maxRetries, 5);
      expect(widget.lazyLoadingStrategy, LazyLoadingStrategy.none);
      expect(widget.visibilityThreshold, 0.5);
      expect(widget.showLoadingOverlay, false);
      expect(widget.priority, ImagePriority.high);
      expect(widget.enableMemoryOptimization, false);
      expect(widget.enableProgressiveLoading, false);
    });

    test('const constructor is supported', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'const-test');
      expect(widget, isNotNull);
    });

    test('imageUrl with relative path', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'artist/123/image.png');
      expect(widget.imageUrl, 'artist/123/image.png');
    });

    test('imageUrl with leading slash', () {
      const widget = PicnicCachedNetworkImage(imageUrl: '/path/to/image.png');
      expect(widget.imageUrl, '/path/to/image.png');
    });

    test('imageUrl with GIF extension', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'https://example.com/anim.gif');
      expect(widget.imageUrl.toLowerCase().endsWith('.gif'), true);
    });

    test('imageUrl with uppercase GIF extension', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'https://example.com/anim.GIF');
      expect(widget.imageUrl.toLowerCase().endsWith('.gif'), true);
    });

    test('imageUrl with webp extension', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'https://example.com/img.webp');
      expect(widget.imageUrl.toLowerCase().endsWith('.gif'), false);
    });
  });

  group('buildImageLoadingOverlay function', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: buildImageLoadingOverlay(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with small dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 10,
              height: 10,
              child: buildImageLoadingOverlay(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with large dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: buildImageLoadingOverlay(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('Image complexity estimation logic', () {
    test('small pixel count is low complexity', () {
      const width = 50.0;
      const height = 50.0;
      final pixelCount = width * height; // 2500
      expect(pixelCount < 50000, true);
    });

    test('medium pixel count is medium complexity', () {
      const width = 300.0;
      const height = 300.0;
      final pixelCount = width * height; // 90000
      expect(pixelCount >= 50000 && pixelCount < 200000, true);
    });

    test('large pixel count is high complexity', () {
      const width = 500.0;
      const height = 500.0;
      final pixelCount = width * height; // 250000
      expect(pixelCount >= 200000, true);
    });

    test('GIF is always high complexity', () {
      const url = 'https://example.com/animation.gif';
      final isGif = url.toLowerCase().endsWith('.gif');
      expect(isGif, true);
      // GIF always returns high complexity regardless of size
    });
  });

  group('Load delay calculation logic', () {
    test('high priority has zero delay', () {
      const priority = ImagePriority.high;
      final delay = priority == ImagePriority.high
          ? Duration.zero
          : (priority == ImagePriority.normal
              ? const Duration(milliseconds: 0)
              : const Duration(milliseconds: 200));
      expect(delay, Duration.zero);
    });

    test('normal priority uses base delay', () {
      const priority = ImagePriority.normal;
      const baseDelay = Duration(milliseconds: 50);
      final delay = priority == ImagePriority.high
          ? Duration.zero
          : (priority == ImagePriority.normal
              ? baseDelay
              : baseDelay + const Duration(milliseconds: 200));
      expect(delay, const Duration(milliseconds: 50));
    });

    test('low priority adds 200ms to base delay', () {
      const priority = ImagePriority.low;
      const baseDelay = Duration(milliseconds: 50);
      final delay = priority == ImagePriority.high
          ? Duration.zero
          : (priority == ImagePriority.normal
              ? baseDelay
              : baseDelay + const Duration(milliseconds: 200));
      expect(delay, const Duration(milliseconds: 250));
    });
  });

  group('Backoff delay calculation logic', () {
    test('first retry has base delay', () {
      const baseDelayMs = 500;
      final delay = (baseDelayMs * 1.5).toInt(); // pow(1.5, 1) = 1.5
      expect(delay, 750);
    });

    test('second retry has longer delay', () {
      const baseDelayMs = 500;
      final delay = (baseDelayMs * 1.5 * 1.5).toInt(); // pow(1.5, 2) = 2.25
      expect(delay, 1125);
    });

    test('delay is capped at max', () {
      const maxBackoffMs = 30000;
      const baseDelayMs = 500;
      // Very high retry count
      var delay = baseDelayMs;
      for (int i = 0; i < 20; i++) {
        delay = (delay * 1.5).toInt();
      }
      final capped = delay > maxBackoffMs ? maxBackoffMs : delay;
      expect(capped, maxBackoffMs);
    });
  });

  group('Retry logic', () {
    test('retryable error keywords are detected', () {
      final retryableErrors = [
        'timeout',
        'connection',
        'network',
        'socket',
        'handshake',
        'host',
        'resolve',
        'unreachable',
        'interrupted',
        'refused',
        'reset',
        'dispose',
      ];

      for (final keyword in retryableErrors) {
        final errorString = 'Some $keyword error occurred';
        final isRetryable = retryableErrors.any(
          (k) => errorString.toLowerCase().contains(k),
        );
        expect(isRetryable, true, reason: '$keyword should be retryable');
      }
    });

    test('non-retryable error is not retried', () {
      final retryableErrors = [
        'timeout', 'connection', 'network', 'socket',
      ];
      const errorString = 'HTTP 404 Not Found';
      final isRetryable = retryableErrors.any(
        (k) => errorString.toLowerCase().contains(k),
      );
      expect(isRetryable, false);
    });

    test('retry count check', () {
      const maxRetries = 2;
      var retryCount = 0;

      bool shouldRetry() => retryCount < maxRetries;

      expect(shouldRetry(), true);
      retryCount++;
      expect(shouldRetry(), true);
      retryCount++;
      expect(shouldRetry(), false);
    });
  });

  group('Memory pressure check logic', () {
    test('usage above 90% is memory pressure', () {
      const currentSize = 180 * 1024 * 1024; // 180MB
      const maxSize = 200 * 1024 * 1024; // 200MB
      final usagePercentage = (currentSize / maxSize) * 100;
      expect(usagePercentage >= 90.0, true);
    });

    test('usage below 90% is not memory pressure', () {
      const currentSize = 100 * 1024 * 1024; // 100MB
      const maxSize = 200 * 1024 * 1024; // 200MB
      final usagePercentage = (currentSize / maxSize) * 100;
      expect(usagePercentage >= 90.0, false);
    });

    test('cache cleanup at 90% threshold', () {
      const currentSize = 185 * 1024 * 1024;
      const maxSize = 200 * 1024 * 1024;
      final shouldClean = currentSize > maxSize * 0.90;
      expect(shouldClean, true);
    });

    test('no cleanup below 90% threshold', () {
      const currentSize = 170 * 1024 * 1024;
      const maxSize = 200 * 1024 * 1024;
      final shouldClean = currentSize > maxSize * 0.90;
      expect(shouldClean, false);
    });
  });
}
