import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

  group('AdShortformFullscreenPage render', () {
    testWidgets('renders with required params', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          AdShortformFullscreenPage(
            videoUrl: 'https://example.com/video.mp4',
            onViewComplete: () async {},
            onMore: () async {},
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      expect(find.byType(AdShortformFullscreenPage), findsOneWidget);
      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders with CTA URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          AdShortformFullscreenPage(
            videoUrl: 'https://example.com/video.mp4',
            ctaUrl: 'https://example.com/cta',
            onViewComplete: () async {},
            onMore: () async {},
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      expect(find.byType(AdShortformFullscreenPage), findsOneWidget);
    });

    testWidgets('shows black background', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          AdShortformFullscreenPage(
            videoUrl: 'https://example.com/video.mp4',
            onViewComplete: () async {},
            onMore: () async {},
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Scaffold should have black background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('renders with loadAd callback', (WidgetTester tester) async {
      bool loadAdCalled = false;

      await tester.pumpWidget(
        buildTestAppPage(
          AdShortformFullscreenPage(
            videoUrl: 'https://example.com/fallback.mp4',
            onViewComplete: () async {},
            onMore: () async {},
            loadAd: () async {
              loadAdCalled = true;
              return (
                videoUrl: 'https://example.com/ad.mp4',
                ctaUrl: 'https://example.com/cta',
                blocked: false,
              );
            },
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(AdShortformFullscreenPage), findsOneWidget);
      expect(loadAdCalled, isTrue);
    });
  });
}
