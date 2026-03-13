import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/animated_heart.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('PulsingHeart', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PulsingHeart(),
        ),
      );
      await tester.pump();

      expect(find.byType(PulsingHeart), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('renders with custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PulsingHeart(size: 48.0),
        ),
      );
      await tester.pump();

      expect(find.byType(PulsingHeart), findsOneWidget);
    });

    testWidgets('renders with custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PulsingHeart(color: Colors.blue),
        ),
      );
      await tester.pump();

      expect(find.byType(PulsingHeart), findsOneWidget);
    });
  });

  group('FancyPulsingHeart', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FancyPulsingHeart(),
        ),
      );
      await tester.pump();

      expect(find.byType(FancyPulsingHeart), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('renders with custom size and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          FancyPulsingHeart(size: 36.0, color: Colors.pink),
        ),
      );
      await tester.pump();

      expect(find.byType(FancyPulsingHeart), findsOneWidget);
    });
  });
}
