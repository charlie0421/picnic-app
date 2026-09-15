import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_platform.dart';

import '../../../../../../helpers/factories/user_factory.dart';
import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/mock_supabase.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// PICNIC-2682 — 최소 수정판.
///
/// `Tapjoy.setUserID` 는 리스너만 등록하고 즉시 반환한다. 플러그인의 Android
/// 구현이 `result.success(null)` 을 리스너 바깥에서 호출하기 때문이다
/// (TapjoyOfferwallPlugin.kt). 그래서 이걸 await 해도 등록 완료를 기다린 것이
/// 아니다.
///
/// 등록이 확정되기 전에 오퍼를 요청하면 Tapjoy 는 "user ID 가 없는 기기" 로
/// 보고 콜백 `snuid` 에 기기 ID 를 실어 보낸다(자체관리 가상화폐 문서). 그
/// 값이 `user_profiles.id` (uuid) 조회를 22P02 로 터뜨린 원인이다.
///
/// 여기서 고정하는 계약: **terminal 이벤트 전에는 오퍼 요청이 나가지 않는다.**
class _ProbePlatform extends TapjoyPlatform {
  _ProbePlatform(super.ref, super.context, super.id, super.animationController);

  int placementRequests = 0;

  /// 사용자에게 뜬 다이얼로그 수.
  ///
  /// `logAdLoadFailure` 는 로그 전용이 아니라 항상 다이얼로그를 띄운다 —
  /// no-fill 이면 `_showNoFillDialog`, 그 외에는 일반 오류 다이얼로그다
  /// (ad_platform.dart:459,478). 이 클래스의 모든 실패 경로가 이걸 거치므로
  /// 호출 수가 곧 다이얼로그 수다.
  int dialogs = 0;

  @override
  void logAdLoadFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    dialogs++;
  }

  @override
  Future<void> requestTapjoyPlacement() async {
    placementRequests++;
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'test-user-id-001';
  const channelName = 'tapjoy_offerwall';

  late List<String> channelCalls;
  late TestDefaultBinaryMessenger messenger;

  setUp(() async {
    initTestColors();
    // 소유권 가드는 static 이다 — 테스트 간 누수를 막는다.
    TapjoyPlatform.resetUserIdGuardForTest();
    channelCalls = <String>[];
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
      call,
    ) async {
      channelCalls.add(call.method);
      return null;
    });
    await setupMockSupabaseWithAuth(<String, dynamic>{}, userId: uid);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(const MethodChannel(channelName), null);
    try {
      OverlayLoadingProgress.stop();
    } catch (_) {
      // 전역 싱글턴 — 켜진 적 없으면 무시한다.
    }
  });

  /// 네이티브가 보내는 terminal 이벤트를 흉내낸다.
  Future<void> deliver(String method, [Object? args]) async {
    await messenger.handlePlatformMessage(
      channelName,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await pumpAndIgnoreErrors(tester);
    }
  }

  Future<_ProbePlatform> buildPlatform(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            capturedContext = context;
            // checkLogin() 이 첫 read 에서 AsyncLoading 을 보지 않게 한다.
            ref.watch(userInfoProvider);
            return const SizedBox.shrink();
          },
        ),
        userProfile: UserFactory.create(),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);
    final platform = _ProbePlatform(
      capturedRef,
      capturedContext,
      'tapjoy',
      controller,
    );
    return platform;
  }

  testWidgets('성공 이벤트 전에는 오퍼를 요청하지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);

    expect(channelCalls, contains('setUserID'));
    expect(
      platform.placementRequests,
      0,
      reason: 'terminal 이벤트 전에 오퍼를 요청하면 snuid 가 기기 ID 로 귀속된다',
    );

    await deliver('TapjoyOnSetUserIDSuccess');
    await drain(tester);
    await showing;

    expect(platform.placementRequests, 1);
    // 30초 안전장치 타이머와 버튼 애니메이션을 정리한다 — pending timer 검사는
    // 본문이 끝나는 시점에 돌아서 tearDown 으로는 늦다.
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('실패 이벤트면 오퍼를 요청하지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    await deliver('TapjoyOnSetUserIDFailure', 'set failed');
    await drain(tester);
    await showing;

    expect(platform.placementRequests, 0);
    expect(
      platform.dialogs,
      1,
      reason: '실패 한 건에 다이얼로그는 한 개여야 한다',
    );
    // 30초 안전장치 타이머와 버튼 애니메이션을 정리한다 — pending timer 검사는
    // 본문이 끝나는 시점에 돌아서 tearDown 으로는 늦다.
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('terminal 이벤트가 오지 않으면 상한 뒤 포기하고 오퍼를 요청하지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    expect(platform.placementRequests, 0);

    // 상한(10s)을 넘긴다. 무한 대기로 버튼이 묶이면 안 된다.
    await tester.pump(const Duration(seconds: 11));
    await drain(tester);
    await showing;

    expect(platform.placementRequests, 0);

    // 같은 계정이면 재시도를 허용한다. 늦은 이벤트가 새 시도의 결과로 처리돼도
    // SDK 가 든 값과 우리가 믿는 값이 같아서 귀속이 엉키지 않는다. 무응답 한
    // 번에 앱 재시작까지 오퍼월이 죽으면 안 된다.
    channelCalls.clear();
    final retry = platform.showAd();
    await drain(tester);
    expect(
      channelCalls,
      contains('setUserID'),
      reason: '같은 계정 재시도까지 막으면 세션 내내 오퍼월이 죽는다',
    );

    await deliver('TapjoyOnSetUserIDSuccess');
    await drain(tester);
    await retry;
    expect(platform.placementRequests, 1);

    // 30초 안전장치 타이머와 버튼 애니메이션을 정리한다 — pending timer 검사는
    // 본문이 끝나는 시점에 돌아서 tearDown 으로는 늦다.
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('미종료 상태에서 계정이 바뀌면 새 setUserID 를 보내지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    await tester.pump(const Duration(seconds: 11));
    await drain(tester);
    await showing;

    // terminal 이벤트를 못 받은 채 계정이 바뀌었다. 여기서 새 요청을 보내면
    // 리스너 슬롯이 바뀌어, 늦게 도착한 앞 계정의 결과가 이 시도의 결과로
    // 둔갑한다 — 적립이 앞 계정에 귀속된다.
    await setupMockSupabaseWithAuth(<String, dynamic>{}, userId: 'other-user');
    channelCalls.clear();
    final switched = platform.showAd();
    await drain(tester);
    await switched;

    expect(
      channelCalls.where((c) => c == 'setUserID'),
      isEmpty,
      reason: '앞 계정의 시도가 종료되기 전에는 다른 계정으로 보내면 안 된다',
    );
    expect(platform.placementRequests, 0);

    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('늦게 도착한 실패 이벤트는 소유권을 돌려준다', (tester) async {
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    await tester.pump(const Duration(seconds: 11));
    await drain(tester);
    await showing;

    // 뒤늦게 terminal 이벤트가 도착하면 그때 소유권이 풀린다.
    await deliver('TapjoyOnSetUserIDFailure', 'late failure');
    await drain(tester);

    channelCalls.clear();
    final retry = platform.showAd();
    await drain(tester);
    expect(channelCalls, contains('setUserID'));

    await deliver('TapjoyOnSetUserIDSuccess');
    await drain(tester);
    await retry;

    expect(platform.placementRequests, 1);
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('연타해도 setUserID 는 겹쳐 나가지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await drain(tester);
    final second = platform.showAd();
    await drain(tester);

    expect(
      channelCalls.where((c) => c == 'setUserID').length,
      1,
      reason: '플러그인 리스너가 static 단일 슬롯이라 겹치면 앞선 대기가 영원히 안 끝난다',
    );

    await deliver('TapjoyOnSetUserIDSuccess');
    await drain(tester);
    await tester.pump(const Duration(seconds: 11));
    await drain(tester);
    await first;
    await second;
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });
}
