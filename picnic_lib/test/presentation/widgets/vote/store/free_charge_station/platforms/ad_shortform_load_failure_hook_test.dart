import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// "광고 로드에 실패했습니다" 가 뜨는 모든 경로가 [AdShortformFullscreenPage.onLoadFailure]
/// 로 정확히 한 번 보고돼야 한다. 보고가 빠지면 QnA 395 처럼 서버에는 발급 행만
/// 남고 원인을 가릴 수 없다.
///
/// 헤드리스 테스트는 실제 VideoPlayerController 를 못 만들므로, 컨트롤러가
/// 준비되기 전에 끝나는 경로(loadAd 예외 · 빈 URL · 워치독)만 여기서 다룬다.
void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

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

  test('initialize timeout is 30s and the watchdog leaves it 5s of slack', () {
    expect(
      AdShortformFullscreenPage.initializeTimeout,
      const Duration(seconds: 30),
    );
    expect(
      AdShortformFullscreenPage.watchdogTimeout,
      const Duration(seconds: 35),
    );
  });

  testWidgets('loadAd throwing is reported once as stage loadAd', (
    tester,
  ) async {
    final reported = <AdShortformLoadFailure>[];
    final page = AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: legacyViewResponse,
      loadAd: () async => throw Exception('issue 500'),
      onLoadFailure: reported.add,
    );

    await pumpPageInRoute(tester, page: page);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

    expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(reported, hasLength(1));
    expect(reported.single.stage, AdShortformLoadStage.loadAd);
    expect(reported.single.reason, 'other');
    expect(reported.single.elapsed, greaterThanOrEqualTo(Duration.zero));
  });

  testWidgets('empty video_url (not blocked) is reported as stage emptyUrl', (
    tester,
  ) async {
    final reported = <AdShortformLoadFailure>[];
    final page = AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: legacyViewResponse,
      loadAd: () async => (videoUrl: '', ctaUrl: null, blocked: false),
      onLoadFailure: reported.add,
    );

    await pumpPageInRoute(tester, page: page);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

    expect(reported, hasLength(1));
    expect(reported.single.stage, AdShortformLoadStage.emptyUrl);
    expect(reported.single.reason, 'state');
    expect(reported.single.videoUrl, isNull);
  });

  testWidgets('anti-abuse block (blocked=true) is not a load failure', (
    tester,
  ) async {
    final reported = <AdShortformLoadFailure>[];
    final page = AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: legacyViewResponse,
      loadAd: () async => (videoUrl: '', ctaUrl: null, blocked: true),
      onLoadFailure: reported.add,
    );

    await pumpPageInRoute(tester, page: page);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

    expect(reported, isEmpty);
  });

  testWidgets('watchdog expiry is reported as stage watchdog / timeout', (
    tester,
  ) async {
    final reported = <AdShortformLoadFailure>[];
    final completer =
        Completer<({String videoUrl, String? ctaUrl, bool blocked})>();
    final page = AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: legacyViewResponse,
      loadAd: () => completer.future, // never completes
      onLoadFailure: reported.add,
    );

    await pumpPageInRoute(tester, page: page);
    expect(reported, isEmpty, reason: 'nothing to report before the watchdog');

    await pumpAndIgnoreErrors(
      tester,
      AdShortformFullscreenPage.watchdogTimeout + const Duration(seconds: 1),
    );
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

    expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(reported, hasLength(1));
    expect(reported.single.stage, AdShortformLoadStage.watchdog);
    expect(reported.single.reason, 'timeout');
    expect(
      reported.single.elapsed,
      greaterThanOrEqualTo(AdShortformFullscreenPage.watchdogTimeout),
    );
  });

  testWidgets('a throwing reporter still lets the error dialog show', (
    tester,
  ) async {
    final page = AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: legacyViewResponse,
      loadAd: () async => throw Exception('issue 500'),
      onLoadFailure: (_) => throw StateError('reporter broken'),
    );

    await pumpPageInRoute(tester, page: page);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

    expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
  });
}

Future<InternalShortformViewResponse> legacyViewResponse() async =>
    const InternalShortformViewResponse(
      ok: true,
      rewardAdded: 1,
      impressionId: '00000000-0000-4000-8000-000000000395',
      newBonus: 1,
    );
