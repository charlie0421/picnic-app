import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// Helper to build and pump a PicnicCachedNetworkImage test.
/// Uses LazyLoadingStrategy.viewport (default) and does NOT call pumpAndSettle
/// to avoid timer issues from CachedNetworkImage internals.
Future<void> _pumpImage(
  WidgetTester tester, {
  required String imageUrl,
  double? width = 100,
  double? height = 100,
  BoxFit? fit,
  BorderRadius? borderRadius,
  LazyLoadingStrategy lazyLoadingStrategy = LazyLoadingStrategy.viewport,
  Widget? placeholder,
  Widget? errorWidget,
  bool showLoadingOverlay = true,
  ImagePriority priority = ImagePriority.normal,
  int? memCacheWidth,
  int? memCacheHeight,
  Duration? lazyLoadDelay,
  Duration? timeout,
  int? maxRetries,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      PicnicCachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        lazyLoadingStrategy: lazyLoadingStrategy,
        placeholder: placeholder,
        errorWidget: errorWidget,
        showLoadingOverlay: showLoadingOverlay,
        priority: priority,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        lazyLoadDelay: lazyLoadDelay,
        timeout: timeout,
        maxRetries: maxRetries,
      ),
    ),
  );
  // Only pump once to avoid timer assertion issues
  await tester.pump();
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('PicnicCachedNetworkImage widget rendering', () {
    testWidgets('renders with required params', (WidgetTester tester) async {
      await _pumpImage(tester, imageUrl: 'https://example.com/test.png');
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom fit and border radius',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom placeholder',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        placeholder: const Icon(Icons.image),
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom error widget',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        errorWidget: const Icon(Icons.error),
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with showLoadingOverlay false',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        showLoadingOverlay: false,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with high priority', (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        priority: ImagePriority.high,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with low priority', (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        priority: ImagePriority.low,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders without explicit width/height',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        width: null,
        height: null,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with memCacheWidth and memCacheHeight',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        memCacheWidth: 200,
        memCacheHeight: 200,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with lazy load delay',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        lazyLoadDelay: const Duration(milliseconds: 100),
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom timeout and maxRetries',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        timeout: const Duration(seconds: 10),
        maxRetries: 5,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with preload strategy',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        lazyLoadingStrategy: LazyLoadingStrategy.preload,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with progressive strategy',
        (WidgetTester tester) async {
      await _pumpImage(
        tester,
        imageUrl: 'https://example.com/test.png',
        lazyLoadingStrategy: LazyLoadingStrategy.progressive,
      );
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });
  });

  group('ImageComplexity enum', () {
    test('has all expected values', () {
      expect(ImageComplexity.values, hasLength(3));
      expect(ImageComplexity.values, contains(ImageComplexity.low));
      expect(ImageComplexity.values, contains(ImageComplexity.medium));
      expect(ImageComplexity.values, contains(ImageComplexity.high));
    });
  });

  group('LazyLoadingStrategy enum', () {
    test('has all expected values', () {
      expect(LazyLoadingStrategy.values, hasLength(4));
      expect(LazyLoadingStrategy.values, contains(LazyLoadingStrategy.none));
      expect(
          LazyLoadingStrategy.values, contains(LazyLoadingStrategy.viewport));
      expect(
          LazyLoadingStrategy.values, contains(LazyLoadingStrategy.preload));
      expect(LazyLoadingStrategy.values,
          contains(LazyLoadingStrategy.progressive));
    });
  });

  group('ImagePriority enum', () {
    test('has all expected values', () {
      expect(ImagePriority.values, hasLength(3));
      expect(ImagePriority.values, contains(ImagePriority.low));
      expect(ImagePriority.values, contains(ImagePriority.normal));
      expect(ImagePriority.values, contains(ImagePriority.high));
    });
  });

  group('buildImageLoadingOverlay', () {
    testWidgets('renders without error', (WidgetTester tester) async {
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
  });
}
