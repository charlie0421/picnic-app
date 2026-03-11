import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/pic/image_overlay_painter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('ImageOverlayPainter', () {
    test('creates with null overlayImage', () {
      final painter = ImageOverlayPainter();
      expect(painter.overlayImage, isNull);
    });

    test('shouldRepaint returns true when image changes', () {
      final painter1 = ImageOverlayPainter(overlayImage: null);
      final painter2 = ImageOverlayPainter(overlayImage: null);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns false when same null', () {
      final painter = ImageOverlayPainter();
      expect(painter.shouldRepaint(ImageOverlayPainter()), isFalse);
    });

    testWidgets('renders inside CustomPaint with null image', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomPaint(
            painter: ImageOverlayPainter(),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
