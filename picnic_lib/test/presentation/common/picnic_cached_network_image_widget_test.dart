import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
    setupMockSupabase({});
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('PicnicCachedNetworkImage additional widget tests', () {
    testWidgets('renders with medium complexity (200x200)', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/medium.jpg',
            width: 200,
            height: 200,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with low complexity (small size)', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/small.jpg',
            width: 30,
            height: 30,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with high complexity (large size)', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/big.jpg',
            width: 600,
            height: 600,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders GIF with high complexity path', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/test.gif',
            width: 200,
            height: 200,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom placeholder widget', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/custom-placeholder.jpg',
            width: 100,
            height: 100,
            placeholder: Center(child: Text('Loading...')),
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with showLoadingOverlay false and viewport strategy', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/no-overlay-viewport.jpg',
            width: 100,
            height: 100,
            showLoadingOverlay: false,
            lazyLoadingStrategy: LazyLoadingStrategy.viewport,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with custom error widget', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/custom-error.jpg',
            width: 100,
            height: 100,
            errorWidget: Icon(Icons.broken_image),
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with borderRadius', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/rounded2.jpg',
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('renders with progressive strategy', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/progressive2.jpg',
            width: 150,
            height: 150,
            lazyLoadingStrategy: LazyLoadingStrategy.progressive,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with low priority and lazy load delay', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/low-delayed.jpg',
            width: 100,
            height: 100,
            priority: ImagePriority.low,
            lazyLoadDelay: Duration(milliseconds: 100),
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders without explicit dimensions', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const SizedBox(
            width: 200,
            height: 200,
            child: PicnicCachedNetworkImage(
              imageUrl: 'https://example.com/no-dims.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with relative URL', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'images/relative.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders with leading slash URL', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: '/images/slash.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });
  });

  group('buildImageLoadingOverlay', () {
    testWidgets('renders shimmer loading overlay', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          SizedBox(
            width: 100,
            height: 100,
            child: buildImageLoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });
}
