import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/goong_hap_intro_dialog.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('GoongHapIntroContent', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GoongHapIntroContent), findsOneWidget);
    });

    testWidgets('shows Korean title 궁합', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('궁합'), findsOneWidget);
    });

    testWidgets('shows Chinese 宮合 and English Goong-Hap', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('宮合'), findsOneWidget);
      expect(find.text('Goong-Hap'), findsOneWidget);
    });

    testWidgets('renders header with gradient', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header contains decorative emojis
      expect(find.text('✨'), findsOneWidget);
      expect(find.text('💜'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);
    });

    testWidgets('renders info section icons', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Info section icons
      expect(find.text('🏯'), findsOneWidget);
      expect(find.text('🎤'), findsOneWidget);
      expect(find.text('💕'), findsOneWidget);
      expect(find.text('🐲'), findsOneWidget);
    });

    testWidgets('renders wave divider via ClipPath', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('renders close button as ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders zodiac animals in Wrap', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have a Wrap widget for zodiac animals
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('close button exists and is tappable', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: GoongHapIntroContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final elevatedButton = find.byType(ElevatedButton);
      expect(elevatedButton, findsOneWidget);

      // Verify the button exists and can be found
      final buttonWidget =
          tester.widget<ElevatedButton>(elevatedButton);
      expect(buttonWidget.onPressed, isNotNull);
    });
  });

  group('WaveClipper', () {
    test('shouldReclip returns false', () {
      final clipper = WaveClipper();
      expect(clipper.shouldReclip(WaveClipper()), false);
    });

    test('getClip returns a valid path', () {
      final clipper = WaveClipper();
      final path = clipper.getClip(const Size(360, 24));
      // Path should be non-null and a valid Path object
      expect(path, isA<Path>());
    });
  });
}
