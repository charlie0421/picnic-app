import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/image_shimmer_loading.dart';

void main() {
  group('buildImageLoadingOverlay', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildImageLoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);

      // Dispose to clean up the repeating animation controller.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('contains a ShimmerLoading widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildImageLoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('ShimmerLoading', () {
    testWidgets('renders with isLoading=true and shows ShaderMask',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              isLoading: true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

      // Pump a frame so the animation builder runs.
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ShaderMask), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders with isLoading=false and shows child directly',
        (tester) async {
      const childKey = Key('shimmer_child');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              isLoading: false,
              child: Container(
                key: childKey,
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // The child should be rendered directly without ShaderMask.
      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('disposes without error (animation controller cleanup)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              isLoading: true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Dispose the widget – should not throw.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('SlidingGradientTransform', () {
    test('transform() returns correct Matrix4 translation', () {
      const transform = SlidingGradientTransform(slidePercent: 0.5);
      const bounds = Rect.fromLTWH(0, 0, 200, 100);

      final matrix = transform.transform(bounds);

      expect(matrix, isNotNull);
      // Translation along x should be bounds.width * slidePercent = 100.
      expect(matrix!.getTranslation().x, 100.0);
      expect(matrix.getTranslation().y, 0.0);
      expect(matrix.getTranslation().z, 0.0);
    });

    test('with slidePercent=0 produces no translation', () {
      const transform = SlidingGradientTransform(slidePercent: 0.0);
      const bounds = Rect.fromLTWH(0, 0, 300, 100);

      final matrix = transform.transform(bounds);

      expect(matrix, isNotNull);
      expect(matrix!.getTranslation().x, 0.0);
      expect(matrix.getTranslation().y, 0.0);
      expect(matrix.getTranslation().z, 0.0);
    });

    test('with slidePercent=1.0 translates by full width', () {
      const transform = SlidingGradientTransform(slidePercent: 1.0);
      const bounds = Rect.fromLTWH(0, 0, 250, 100);

      final matrix = transform.transform(bounds);

      expect(matrix, isNotNull);
      expect(matrix!.getTranslation().x, 250.0);
      expect(matrix.getTranslation().y, 0.0);
      expect(matrix.getTranslation().z, 0.0);
    });
  });
}
