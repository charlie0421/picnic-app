import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// 리뷰 지적: initialize() 는 끝났는데 그 뒤 setLooping()/setVolume() 이 워치독
/// (35초)을 넘겨 멈추면, 워치독이 오류 다이얼로그를 띄운 **뒤에** 후속 코드가
/// 컨트롤러를 등록하고 play() 를 불러 다이얼로그 뒤에서 재생이 시작된다.
///
/// [VideoPlayerPlatform.instance] 를 제어 가능한 가짜로 바꿔 그 순서를 헤드리스로
/// 재현한다. 실제 플러그인은 여기서 전혀 쓰지 않는다.
void main() {
  late void Function() restore;
  late VideoPlayerPlatform original;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
    original = VideoPlayerPlatform.instance;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = original;
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

  testWidgets(
    'setLooping hanging past the watchdog: dialog shows, and the late '
    'completion neither registers the controller nor plays',
    (tester) async {
      // Completer 는 테스트(FakeAsync) 존 안에서 만들어야 완료 콜백이 pump 로
      // 흐른다. setUp 에서 만들면 실제 마이크로태스크로 빠져 pump 가 못 본다.
      final platform = _HangingLoopingPlatform();
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

      await pumpAndIgnoreErrors(
        tester,
        AdShortformFullscreenPage.watchdogTimeout + const Duration(seconds: 1),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.text('광고 로드에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);
      expect(reported.map((f) => f.stage), [AdShortformLoadStage.watchdog]);

      // 이제 setLooping 이 뒤늦게 돌아온다.
      platform.releaseLooping();
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(platform.playCalls, 0, reason: '다이얼로그 뒤에서 재생되면 안 된다');
      expect(platform.disposed, isTrue, reason: '버려진 컨트롤러는 정리돼야 한다');
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

/// create → 즉시 initialized 이벤트, setLooping 은 [releaseLooping] 까지 대기.
class _HangingLoopingPlatform extends VideoPlayerPlatform {
  static const int _playerId = 7;

  // 컨트롤러는 create 가 끝난 뒤에야 videoEventsFor 를 구독하므로, 이벤트는
  // 구독 시점(onListen)에 내보내야 한다. 먼저 보내면 broadcast 라 사라진다.
  // 단일 구독 + onCancel: broadcast 컨트롤러는 구독 취소 시 루트 존의 상수
  // future(_nullFuture)를 돌려주고, 컨트롤러 dispose 가 그걸 await 하는 순간
  // 가짜 시간 밖으로 빠져 pump 로는 끝나지 않는다. 단일 구독 컨트롤러는
  // onCancel 이 돌려준(테스트 존) future 를 그대로 전달한다.
  late final _events = StreamController<VideoEvent>(
    onListen: _emitInitialized,
    onCancel: () async {},
  );
  final _looping = Completer<void>();

  void _emitInitialized() {
    scheduleMicrotask(() {
      _events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 19),
          size: const Size(1080, 1920),
          rotationCorrection: 0,
        ),
      );
    });
  }

  bool created = false;
  bool disposed = false;
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
  Future<void> setLooping(int playerId, bool looping) {
    loopingCalls += 1;
    return _looping.future;
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
    disposed = true;
  }

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}
