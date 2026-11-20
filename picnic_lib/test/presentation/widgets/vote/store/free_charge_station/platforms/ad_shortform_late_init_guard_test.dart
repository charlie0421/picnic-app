import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// 실제 VideoPlayerController 와 제어 가능한 플랫폼으로 초기화 실패·늦은 완료의
/// 정리 및 재생·보고·보상 계약을 검증한다.
void main() {
  late VideoPlayerPlatform original;

  setUp(() {
    initTestColors();
    original = VideoPlayerPlatform.instance;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = original;
  });

  Future<void> pumpIgnoringImageErrors(
    WidgetTester tester, [
    Duration? duration,
  ]) async {
    final restore = suppressImageErrors();
    try {
      await tester.pump(duration);
    } finally {
      restore();
    }
  }

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
    await pumpIgnoringImageErrors(tester);
    await tester.tap(find.text('open'));
    await pumpIgnoringImageErrors(tester);
    await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
  }

  Future<void> popPageInRoute(WidgetTester tester) async {
    final restore = suppressImageErrors();
    try {
      Navigator.of(
        tester.element(find.byType(AdShortformFullscreenPage)),
      ).pop();
      // 플랫폼별 reverse transition 이 끝나야 route 와 State 가 제거된다.
      await tester.pumpAndSettle();
    } finally {
      restore();
    }
    expect(find.byType(AdShortformFullscreenPage), findsNothing);
  }

  AdShortformFullscreenPage createPage(
    List<AdShortformLoadFailure> reported,
    Future<InternalShortformViewResponse> Function() onViewComplete,
  ) {
    return AdShortformFullscreenPage(
      videoUrl: '',
      onViewComplete: onViewComplete,
      loadAd: () async => (
        videoUrl: 'https://cdn.example.com/a/master.m3u8',
        ctaUrl: null,
        blocked: false,
      ),
      onLoadFailure: reported.add,
    );
  }

  testWidgets(
    'initialize timeout disposes once without delaying the error dialog, '
    'and late events cannot play or reward',
    (tester) async {
      final disposeGate = Completer<void>();
      final platform = _ControlledVideoPlatform(disposeGate: disposeGate);
      VideoPlayerPlatform.instance = platform;
      final reported = <AdShortformLoadFailure>[];
      var rewards = 0;
      final page = createPage(reported, () {
        rewards += 1;
        return _legacyViewResponse();
      });

      await pumpPageInRoute(tester, page: page);
      expect(platform.created, isTrue);
      await pumpIgnoringImageErrors(tester, const Duration(seconds: 29));
      expect(platform.disposeCalls, 0);
      expect(reported, isEmpty);

      await pumpIgnoringImageErrors(tester, const Duration(seconds: 1));
      await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
      expect(platform.disposeCalls, 1);
      expect(disposeGate.isCompleted, isFalse);
      expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
      expect(reported, hasLength(1));
      expect(reported.single.stage, AdShortformLoadStage.initialize);
      expect(reported.single.reason, 'timeout');
      expect(platform.playCalls, 0);
      expect(rewards, 0);

      platform.emitInitialized();
      platform.emitCompleted();
      disposeGate.complete();
      await pumpIgnoringImageErrors(tester, const Duration(seconds: 6));
      expect(platform.disposeCalls, 1);
      expect(reported, hasLength(1), reason: '워치독·늦은 이벤트도 중복 보고하지 않는다');
      expect(platform.playCalls, 0);
      expect(rewards, 0);
      expect(find.byType(VideoPlayer), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpIgnoringImageErrors(tester);
      expect(platform.disposeCalls, 1, reason: '페이지 종료가 다시 정리하지 않는다');
    },
  );

  testWidgets('VideoError during initialize disposes and reports once', (
    tester,
  ) async {
    final platform = _ControlledVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    final reported = <AdShortformLoadFailure>[];
    var rewards = 0;
    final page = createPage(reported, () {
      rewards += 1;
      return _legacyViewResponse();
    });

    await pumpPageInRoute(tester, page: page);
    expect(platform.created, isTrue);
    expect(platform.disposeCalls, 0);
    platform.emitVideoError();
    await pumpIgnoringImageErrors(tester);
    await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
    expect(platform.disposeCalls, 1);
    expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(reported, hasLength(1));
    expect(reported.single.stage, AdShortformLoadStage.initialize);
    expect(reported.single.reason, 'platform:VideoError');

    platform.emitInitialized();
    platform.emitCompleted();
    await pumpIgnoringImageErrors(tester, const Duration(seconds: 36));
    expect(platform.disposeCalls, 1);
    expect(reported, hasLength(1));
    expect(platform.playCalls, 0);
    expect(rewards, 0);
    expect(find.byType(VideoPlayer), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpIgnoringImageErrors(tester);
    expect(platform.disposeCalls, 1);
  });

  for (final timeoutAfterPop in [false, true]) {
    testWidgets(
      'route pop before initialize ${timeoutAfterPop ? 'timeout' : 'completion'} '
      'disposes once without playing, reporting or rewarding',
      (tester) async {
        final platform = _ControlledVideoPlatform();
        VideoPlayerPlatform.instance = platform;
        final reported = <AdShortformLoadFailure>[];
        var rewards = 0;
        final page = createPage(reported, () {
          rewards += 1;
          return _legacyViewResponse();
        });

        await pumpPageInRoute(tester, page: page);
        expect(platform.created, isTrue);
        await popPageInRoute(tester);
        expect(platform.disposeCalls, 0);

        if (timeoutAfterPop) {
          await pumpIgnoringImageErrors(tester, const Duration(seconds: 30));
          expect(platform.disposeCalls, 1);
        }
        platform.emitInitialized();
        platform.emitCompleted();
        await pumpIgnoringImageErrors(tester);
        await pumpIgnoringImageErrors(tester, const Duration(seconds: 36));
        expect(platform.disposeCalls, 1);
        expect(reported, isEmpty, reason: '닫힌 페이지의 초기화 종료는 취소다');
        expect(platform.playCalls, 0);
        expect(rewards, 0);
      },
    );
  }

  testWidgets('successful initialize keeps the controller until route pop', (
    tester,
  ) async {
    final platform = _ControlledVideoPlatform(initializeOnListen: true);
    VideoPlayerPlatform.instance = platform;
    final reported = <AdShortformLoadFailure>[];
    var rewards = 0;
    final page = createPage(reported, () {
      rewards += 1;
      return _legacyViewResponse();
    });

    await pumpPageInRoute(tester, page: page);
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(platform.playCalls, 1);
    expect(platform.disposeCalls, 0);
    await pumpIgnoringImageErrors(tester, const Duration(seconds: 36));
    expect(platform.disposeCalls, 0);
    expect(reported, isEmpty);
    expect(rewards, 0);

    await popPageInRoute(tester);
    expect(platform.disposeCalls, 1);
    platform.emitCompleted();
    await pumpIgnoringImageErrors(tester);
    expect(platform.disposeCalls, 1);
    expect(platform.playCalls, 1);
    expect(reported, isEmpty);
    expect(rewards, 0);
  });

  testWidgets(
    'setLooping hanging past the watchdog: dialog shows, and the late '
    'completion neither registers the controller nor plays',
    (tester) async {
      // Completer 는 테스트(FakeAsync) 존 안에서 만들어야 완료 콜백이 pump 로
      // 흐른다. setUp 에서 만들면 실제 마이크로태스크로 빠져 pump 가 못 본다.
      final platform = _ControlledVideoPlatform(
        initializeOnListen: true,
        hangLooping: true,
      );
      VideoPlayerPlatform.instance = platform;
      final reported = <AdShortformLoadFailure>[];
      final page = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: _legacyViewResponse,
        loadAd: () async => (
          videoUrl: 'https://cdn.example.com/a/master.m3u8',
          ctaUrl: null,
          blocked: false,
        ),
        onLoadFailure: reported.add,
      );

      await pumpPageInRoute(tester, page: page);
      // initialize() 는 끝났고 setLooping() 에서 멈춰 있다. (컨트롤러 자체도
      // initialized 직후 setLooping 을 한 번 더 부르므로 1 이상으로 본다.)
      expect(platform.created, isTrue);
      expect(platform.loopingCalls, greaterThanOrEqualTo(1));
      expect(platform.playCalls, 0);

      await pumpIgnoringImageErrors(
        tester,
        AdShortformFullscreenPage.watchdogTimeout + const Duration(seconds: 1),
      );
      await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
      expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
      expect(reported.map((f) => f.stage), [AdShortformLoadStage.watchdog]);

      // 이제 setLooping 이 뒤늦게 돌아온다.
      platform.releaseLooping();
      await pumpIgnoringImageErrors(tester);
      await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
      await pumpIgnoringImageErrors(tester, const Duration(milliseconds: 300));
      expect(platform.playCalls, 0, reason: '다이얼로그 뒤에서 재생되면 안 된다');
      expect(platform.disposeCalls, 1, reason: '버려진 컨트롤러는 한 번 정리돼야 한다');
      expect(find.byType(VideoPlayer), findsNothing);
      expect(reported, hasLength(1), reason: '보고는 여전히 한 번');
    },
  );
}

Future<InternalShortformViewResponse> _legacyViewResponse() async =>
    const InternalShortformViewResponse(
      ok: true,
      rewardAdded: 1,
      impressionId: '00000000-0000-4000-8000-000000000396',
      newBonus: 1,
    );

/// initialized·VideoError·completed 이벤트와 setLooping·dispose 완료를 제어한다.
class _ControlledVideoPlatform extends VideoPlayerPlatform {
  _ControlledVideoPlatform({
    this.initializeOnListen = false,
    this.hangLooping = false,
    this.disposeGate,
  });

  static const int _playerId = 7;
  final bool initializeOnListen;
  final bool hangLooping;
  final Completer<void>? disposeGate;

  // 컨트롤러는 create 가 끝난 뒤에야 videoEventsFor 를 구독하므로,
  // 자동 initialized 이벤트는 구독 시점(onListen)에 내보낸다.
  // 단일 구독 + onCancel: broadcast 컨트롤러는 구독 취소 시 루트 존의 상수
  // future(_nullFuture)를 돌려주고, 컨트롤러 dispose 가 그걸 await 하는 순간
  // 가짜 시간 밖으로 빠져 pump 로는 끝나지 않는다. 단일 구독 컨트롤러는
  // onCancel 이 돌려준(테스트 존) future 를 그대로 전달한다.
  late final _events = StreamController<VideoEvent>(
    onListen: () {
      if (initializeOnListen) scheduleMicrotask(emitInitialized);
    },
    onCancel: () async {},
  );
  final _looping = Completer<void>();

  void emitInitialized() {
    _events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 19),
        size: const Size(1080, 1920),
        rotationCorrection: 0,
      ),
    );
  }

  void emitVideoError() {
    _events.addError(
      PlatformException(code: 'VideoError', message: 'decoder failed'),
    );
  }

  void emitCompleted() {
    _events.add(VideoEvent(eventType: VideoEventType.completed));
  }

  bool created = false;
  int disposeCalls = 0;
  int loopingCalls = 0;
  int playCalls = 0;

  void releaseLooping() {
    if (!_looping.isCompleted) _looping.complete();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<int?> create(DataSource dataSource) async => _create();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _create();

  int _create() {
    created = true;
    return _playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    loopingCalls += 1;
    if (hangLooping) await _looping.future;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> play(int playerId) async {
    playCalls += 1;
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async {
    disposeCalls += 1;
    if (disposeGate != null) await disposeGate!.future;
  }

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}
