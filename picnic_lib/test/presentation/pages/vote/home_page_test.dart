import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/presentation/pages/vote/home_page.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/home_view_state_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

class DeferredLatestMedia extends AsyncLatestMedia {
  DeferredLatestMedia(this.completer);

  final Completer<List<VideoInfo>> completer;

  @override
  Future<List<VideoInfo>> build() => completer.future;
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'banner': <dynamic>[],
      'reward': <dynamic>[],
      'vote': <dynamic>[],
      'media': <dynamic>[],
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('HomePage render', () {
    testWidgets('renders empty state without crashing', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);

      // 홈은 세로로 긴 스크롤 화면이라 headless 뷰포트에서 레이아웃 overflow가
      // 발생할 수 있다. 이는 실기기(더 큰 높이)에서는 스크롤로 해소되는
      // 테스트 환경 아티팩트이므로 overflow 예외만 허용하고, 그 외 예외는 실패시킨다.
      final exception = tester.takeException();
      if (exception != null) {
        final isOverflow =
            exception is FlutterError &&
            exception.message.contains('overflowed');
        expect(
          isOverflow,
          isTrue,
          reason: 'unexpected non-overflow exception: $exception',
        );
      }
    });

    testWidgets(
      'real tab replacement keeps provider data and restores scroll state',
      (tester) async {
        tester.view.physicalSize = const Size(1125, 450);
        tester.view.devicePixelRatio = 3;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });
        final showHome = ValueNotifier(true);
        addTearDown(showHome.dispose);

        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<bool>(
              valueListenable: showHome,
              builder: (_, visible, _) =>
                  visible ? const HomePage() : const SizedBox.expand(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final firstVoteRequests = capturedMockRequests
            .where((uri) => uri.path.contains('/rest/v1/vote'))
            .length;
        final firstMediaRequests = capturedMockRequests
            .where((uri) => uri.path.contains('/rest/v1/media'))
            .length;
        final firstRewardRequests = capturedMockRequests
            .where((uri) => uri.path.contains('/rest/v1/reward'))
            .length;
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
        );
        container.read(homeViewStateProvider.notifier).saveScrollOffset(120);

        showHome.value = false;
        await tester.pump();
        showHome.value = true;
        await tester.pump();
        await tester.pump();

        expect(
          container.read(asyncActiveFeaturedVotesProvider).hasValue,
          isTrue,
        );
        expect(container.read(asyncLatestMediaProvider).hasValue, isTrue);
        expect(container.read(asyncRewardListProvider).hasValue, isTrue);
        expect(
          capturedMockRequests
              .where((uri) => uri.path.contains('/rest/v1/vote'))
              .length,
          firstVoteRequests,
        );
        expect(
          capturedMockRequests
              .where((uri) => uri.path.contains('/rest/v1/media'))
              .length,
          firstMediaRequests,
        );
        expect(
          capturedMockRequests
              .where((uri) => uri.path.contains('/rest/v1/reward'))
              .length,
          firstRewardRequests,
        );
        final list = tester.widget<ListView>(
          find.descendant(
            of: find.byType(HomePage),
            matching: find.byType(ListView),
          ),
        );
        expect(list.controller!.offset, greaterThan(0));
      },
    );

    testWidgets('user scroll cancels a delayed home offset restore', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 450);
      tester.view.devicePixelRatio = 3;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      final latest = Completer<List<VideoInfo>>();

      await tester.pumpWidget(
        buildTestApp(
          const HomePage(),
          extraOverrides: [
            asyncLatestMediaProvider.overrideWith(
              () => DeferredLatestMedia(latest),
            ),
          ],
        ),
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      container.read(homeViewStateProvider.notifier).saveScrollOffset(120);
      final listFinder = find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(ListView),
      );
      final list = tester.widget<ListView>(listFinder);
      await tester.drag(listFinder, const Offset(0, -30));
      await tester.pump();

      latest.complete(const <VideoInfo>[]);
      await tester.pump();
      await tester.pump();

      expect(list.controller!.offset, greaterThan(0));
      expect(list.controller!.offset, isNot(closeTo(120, 0.1)));
      expect(
        container.read(homeViewStateProvider).scrollOffset,
        closeTo(list.controller!.offset, 0.1),
      );
    });

    testWidgets(
      'restore waits for a later usable extent without overwriting target',
      (tester) async {
        tester.view.physicalSize = const Size(1125, 2436);
        tester.view.devicePixelRatio = 3;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
        });

        final latest = Completer<List<VideoInfo>>();
        await tester.pumpWidget(
          buildTestApp(
            const HomePage(),
            // Match the app's split-screen policy so shrinking the viewport
            // leaves a usable extent instead of also collapsing every .h gap.
            splitScreenMode: true,
            extraOverrides: [
              asyncLatestMediaProvider.overrideWith(
                () => DeferredLatestMedia(latest),
              ),
            ],
          ),
        );
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
        );
        container.read(homeViewStateProvider.notifier).saveScrollOffset(120);
        latest.complete(const <VideoInfo>[]);

        // One provider-completion frame plus its restore post-frame callback
        // resolves short content; no manually driven retry-frame loop exists.
        await tester.pump();
        await tester.pump();
        final listFinder = find.descendant(
          of: find.byType(HomePage),
          matching: find.byType(ListView),
        );
        final list = tester.widget<ListView>(listFinder);
        expect(list.controller!.offset, lessThan(120));
        expect(container.read(homeViewStateProvider).scrollOffset, 120);

        // A later layout increases maxScrollExtent; the original target must
        // still win and the restore-induced notification must not erase it.
        tester.view.physicalSize = const Size(1125, 450);
        await tester.pump();
        await tester.pump();
        expect(
          list.controller!.position.maxScrollExtent,
          greaterThanOrEqualTo(120),
        );
        expect(list.controller!.offset, closeTo(120, 0.1));
        expect(container.read(homeViewStateProvider).scrollOffset, 120);
      },
    );
  });
}
