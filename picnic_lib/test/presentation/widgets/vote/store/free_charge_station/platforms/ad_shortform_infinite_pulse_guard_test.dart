import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// Regression tests for the "infinite loading pulse" defect:
/// when the video controller never initializes (server failure, empty
/// video_url, or a network stall), the page must still offer an escape
/// route and surface an error instead of pulsing forever.
///
/// Headless widget tests cannot create a real VideoPlayerController, so the
/// controller stays `null` for the whole test — which is exactly the stuck
/// state we want to verify the guards handle.
void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

  /// Pushes the page onto a fresh route so that closing it via Navigator.pop
  /// is observable through the surviving route count.
  Future<void> pumpPageInRoute(
    WidgetTester tester, {
    required AdShortformFullscreenPage page,
  }) async {
    await tester.pumpWidget(
      buildTestAppPage(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => page));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    await tester.tap(find.text('open'));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
  }

  group('infinite pulse escape — close button always rendered', () {
    testWidgets(
      'close (X) button is rendered while controller is null (loadAd never completes)',
      (WidgetTester tester) async {
        final completer =
            Completer<({String videoUrl, String? ctaUrl, bool blocked})>();
        final page = AdShortformFullscreenPage(
          videoUrl: '',
          onViewComplete: legacyViewResponse,
          loadAd: () => completer.future, // never completes -> controller null
        );

        await pumpPageInRoute(tester, page: page);

        // The page is on screen but the controller has not initialized.
        expect(find.byType(AdShortformFullscreenPage), findsOneWidget);
        // Escape hatch: the close icon must be rendered even with null controller.
        expect(find.byIcon(Icons.close), findsOneWidget);
        final closeTarget = find.byKey(const Key('ad-shortform-close'));
        expect(closeTarget, findsOneWidget);
        expect(tester.getSize(closeTarget).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(closeTarget).height, greaterThanOrEqualTo(48));
      },
    );

    testWidgets(
      'tapping close while controller is null pops the route (no infinite pulse)',
      (WidgetTester tester) async {
        final completer =
            Completer<({String videoUrl, String? ctaUrl, bool blocked})>();
        final page = AdShortformFullscreenPage(
          videoUrl: '',
          onViewComplete: legacyViewResponse,
          loadAd: () => completer.future,
        );

        await pumpPageInRoute(tester, page: page);
        expect(find.byType(AdShortformFullscreenPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        // Let the pop + route exit transition settle. pumpAndSettle would hang on
        // the infinite pulse animation, so pump fixed frames instead.
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

        // Route popped — the user escaped the stuck loader.
        expect(find.byType(AdShortformFullscreenPage), findsNothing);
      },
    );
  });

  group('empty / failed videoUrl surfaces error (not silent infinite pulse)', () {
    testWidgets(
      'empty videoUrl with blocked=false shows error dialog and pops route',
      (WidgetTester tester) async {
        final page = AdShortformFullscreenPage(
          videoUrl: '',
          onViewComplete: legacyViewResponse,
          loadAd: () async => (videoUrl: '', ctaUrl: null, blocked: false),
        );

        await pumpPageInRoute(tester, page: page);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // An error dialog is shown rather than pulsing forever.
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
      },
    );

    testWidgets(
      'blocked=true (anti-abuse) does NOT show an error dialog (silent pop)',
      (WidgetTester tester) async {
        final page = AdShortformFullscreenPage(
          videoUrl: '',
          onViewComplete: legacyViewResponse,
          loadAd: () async => (videoUrl: '', ctaUrl: null, blocked: true),
        );

        await pumpPageInRoute(tester, page: page);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // anti-abuse path handles its own rate-limited dialog; the page must not
        // raise a duplicate video-load error dialog.
        expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsNothing);
      },
    );
  });
}

Future<InternalShortformViewResponse> legacyViewResponse() async =>
    const InternalShortformViewResponse(
      ok: true,
      rewardAdded: 1,
      impressionId: '00000000-0000-4000-8000-000000000402',
      newBonus: 1,
    );
