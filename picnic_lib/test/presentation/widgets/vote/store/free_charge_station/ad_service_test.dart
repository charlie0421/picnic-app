import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

/// 광고 구좌가 켠 적 없는 "남의" 전역 오버레이를 나타내는 마커.
///
/// 패키지 기본 위젯에 기대지 않는 이유: 무료충전소가 쓰는 인디케이터와 타입이
/// 겹치면 "dispose 가 남의 오버레이를 닫았는지"를 구분할 수 없다. 눈에 띄는
/// 자체 키를 쓰면 그 구분이 확실해지고, ScreenUtil 같은 부수 의존도 없다.
const _foreignOverlayKey = ValueKey<String>('foreign-overlay');
const Widget _foreignOverlay = SizedBox(
  key: _foreignOverlayKey,
  width: 8,
  height: 8,
);

typedef _Harness = ({WidgetRef ref, BuildContext context, AdService service});

void main() {
  setUp(initTestColors);

  // 전역 오버레이 누수 차단.
  //
  // OverlayLoadingProgress 는 프로세스 전역 싱글턴이다. 한 테스트가 실패해
  // stop() 을 못 부르고 끝나면 그 상태가 다음 테스트로 그대로 넘어가고, 이후
  // start() 가 통째로 무시되면서 원인과 무관한 테스트까지 연쇄로 깨진다
  // (2026-09-08 RED 로그의 세 번째 실패가 정확히 그 연쇄였다). 성공·실패와
  // 무관하게 매 테스트 끝에 강제로 내린다.
  tearDown(() {
    try {
      OverlayLoadingProgress.stop();
    } catch (error) {
      // 위젯 트리가 이미 해제된 뒤일 수 있다. 정리 실패가 원래 실패 원인을
      // 덮어쓰지 않도록 삼키되, 흔적은 남긴다.
      debugPrint('overlay teardown ignored: $error');
    }
  });

  /// ProviderScope + ScreenUtilInit + MaterialApp 위에 AdService 하나를 세운다.
  ///
  /// [buildTestApp] 을 쓰는 이유는 ScreenUtil 때문이다. 무료충전소 공용 로딩
  /// 인디케이터(`AdLoadingOverlay.indicator`)는 [PulseLoadingIndicator] 이고,
  /// 그 build 는 `size.w` 로 ScreenUtil 을 읽는다 — ScreenUtilInit 이 없으면
  /// 오버레이가 뜨는 순간 `LateInitializationError: Field '_data'` 로 빌드가
  /// 죽는다. 또 인디케이터의 `Image.asset('assets/app_icon_128.png')` 는 테스트
  /// 번들에 실물이 없어 반드시 실패하므로, 이미지/에셋 계열 에러만 걸러 주는
  /// [pumpWidgetAndIgnoreErrors] / [pumpAndIgnoreErrors] 로 pump 한다(그 외
  /// 예외는 원인 위젯 정보와 함께 그대로 다시 던져진다).
  Future<_Harness> pumpHarness(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // ScreenUtilInit 은 크기를 얻기 전 첫 프레임에 자식을 그리지 않을 수 있다.
    // 한 프레임 더 돌려야 Consumer 가 확실히 빌드되고 ScreenUtil 도 준비된다.
    await pumpAndIgnoreErrors(tester);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    // 본문이 중간에 실패해도 컨트롤러는 반드시 해제한다.
    addTearDown(controller.dispose);
    final service = AdService(
      ref: capturedRef,
      context: capturedContext,
      animationController: controller,
    );
    // 사전 단언 실패 시에도 서비스부터 정리한 뒤 컨트롤러를 해제한다.
    addTearDown(service.dispose);
    return (
      ref: capturedRef,
      context: capturedContext,
      service: service,
    );
  }

  testWidgets('harness 는 본문에서 dispose 하지 않아도 플랫폼을 정리한다', (tester) async {
    final platforms = <AdPlatform>[];
    // harness 정리보다 먼저 등록해 정리 후 상태를 확인한다(tearDown은 역순).
    addTearDown(() {
      expect(platforms, isNotEmpty);
      for (final platform in platforms) {
        expect(platform.isDisposed, isTrue, reason: platform.id);
      }
    });
    final harness = await pumpHarness(tester);
    platforms.add(harness.service.getPlatform('pangle')!);
    // 명시적 dispose 없이 본문을 끝내도 실패 경로와 같은 자동 정리가 필요하다.
  });

  testWidgets('dispose 는 모든 플랫폼을 dispose 한다', (tester) async {
    // 프로덕션 결함 (PICNIC-APP-5G9): dispose 가 _platforms.clear() 만 하고
    // 각 플랫폼의 dispose() 를 호출하지 않아, PanglePlatform 의 pollingSignals
    // 구독이 페이지 unmount 후에도 살아남아 dispose 된 ref 를 계속 읽었다.
    final harness = await pumpHarness(tester);
    final platforms = [
      for (final id in [
        'admob',
        'pangle',
        'tapjoy',
        'pincrux',
        'internal-shortform',
      ])
        harness.service.getPlatform(id)!,
    ];

    harness.service.dispose();

    for (final platform in platforms) {
      expect(platform.isDisposed, isTrue, reason: platform.id);
    }
  });

  testWidgets('dispose 는 진행 중이던 로딩 오버레이를 내린다', (tester) async {
    // AdPlatform.dispose 는 _isDisposed 를 먼저 세워 stopAllAnimations 경로가
    // 전부 no-op 이었다. 로딩 오버레이는 전역이라 페이지가 죽어도 남는다.
    final harness = await pumpHarness(tester);

    harness.service.getPlatform('pangle')!.startLoading();
    // startLoading 은 오버레이를 unawaited 로 띄운다 — 삽입이 보이려면 프레임이
    // 한 번 더 필요하다.
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);

    // 예전에는 CircularProgressIndicator 를 찾았지만, 공용 인디케이터가
    // Pulse 로 통일된 뒤(AdLoadingOverlay.indicator) 그 finder 는 어떤 경우에도
    // 0개라 "오버레이가 떴는지" 자체를 못 본다. 실제로 뜨는 위젯을 본다.
    expect(find.byType(PulseLoadingIndicator), findsOneWidget);
    expect(
      tester
          .widget<PulseLoadingIndicator>(find.byType(PulseLoadingIndicator))
          .size,
      40,
      reason: 'AdLoadingOverlay.indicator 는 Medium(40) 이다',
    );
    // 사후 조건이 공허하게 참이 되지 않도록 사전 조건도 못 박는다.
    expect(harness.ref.read(adLoadingStateProvider)['pangle'], isTrue);

    harness.service.dispose();
    await pumpAndIgnoreErrors(tester);

    expect(find.byType(PulseLoadingIndicator), findsNothing);
    // 전역 로딩 상태도 함께 해제돼야 다음 방문의 버튼이 잠기지 않는다.
    expect(harness.ref.read(adLoadingStateProvider)['pangle'], isNot(isTrue));
  });

  testWidgets('dispose 는 자신이 켜지 않은 오버레이는 건드리지 않는다', (tester) async {
    // OverlayLoadingProgress 는 전역 싱글턴이다. 플랫폼이 켠 적 없는
    // 오버레이(다른 기능 소유)를 dispose 가 닫아 버리면 안 된다.
    final harness = await pumpHarness(tester);
    final pangle = harness.service.getPlatform('pangle')!;

    OverlayLoadingProgress.start(
      harness.context,
      widget: _foreignOverlay,
    ); // 다른 기능의 오버레이
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);
    expect(find.byKey(_foreignOverlayKey), findsOneWidget);

    harness.service.dispose();
    await pumpAndIgnoreErrors(tester);

    // dispose 가 실제로 돌았다는 증거가 없으면 "남의 오버레이가 남아 있다"는
    // 것만으로는 아무것도 증명하지 못한다 (아무 일도 안 해도 통과한다).
    expect(pangle.isDisposed, isTrue);
    expect(
      find.byKey(_foreignOverlayKey),
      findsOneWidget,
      reason: '켠 적 없는 전역 오버레이는 dispose 의 정리 대상이 아니다',
    );

    // 소유자가 내리면 실제로 사라진다 — 위 단언이 "안 지워지는 오버레이라서"
    // 통과한 게 아님을 함께 고정한다.
    OverlayLoadingProgress.stop();
    await pumpAndIgnoreErrors(tester);
    expect(find.byKey(_foreignOverlayKey), findsNothing);
  });
}
