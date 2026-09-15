import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/tapjoy_session.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_platform.dart';

import '../../../../../../helpers/factories/user_factory.dart';
import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// PICNIC-2682.
///
/// [TapjoySession] 단위 테스트만으로는 **배선이 고정되지 않는다** —
/// `showAd()` 가 세션을 거치지 않고 곧장 placement 를 요청하도록 되돌려도 세션
/// 테스트는 전부 통과한다. 여기서는 실제 [TapjoyPlatform.showAd] 를 호출해
/// `setUserID` 성공 이벤트 전에는 오퍼월 요청이 나가지 않는지 고정한다.
class _ProbePlatform extends TapjoyPlatform {
  _ProbePlatform(super.ref, super.context, super.id, super.animationController);

  final List<String> requestedFor = <String>[];

  @override
  Future<void> requestPlacement(String userId) async {
    requestedFor.add(userId);
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    handledErrors.add(error);
  }

  final List<Object?> handledErrors = <Object?>[];

}

void main() {
  const uid = 'test-user-id-001'; // UserFactory.create() 의 기본 id

  late List<String> setCalls;
  late List<Completer<void>> gates;
  late String? currentUser;
  late TapjoySession session;

  /// 네이티브 SDK 가 들고 있는 사용자 ID.
  String? nativeUserId;

  Future<TapjoyUserIdAttempt> fakeSetUserId(String userId) async {
    setCalls.add(userId);
    final gate = Completer<void>();
    gates.add(gate);
    // Android SDK 는 HTTP 검증 이전에 로컬 ID 를 먼저 반영한다.
    nativeUserId = userId;
    return TapjoyUserIdAttempt(userId, gate.future);
  }

  setUp(initTestColors);

  // 전역 오버레이 누수 차단 — OverlayLoadingProgress 는 프로세스 전역 싱글턴이다.
  tearDown(() {
    try {
      OverlayLoadingProgress.stop();
    } catch (error) {
      debugPrint('overlay teardown ignored: $error');
    }
  });

  setUp(() {
    setCalls = <String>[];
    gates = <Completer<void>>[];
    currentUser = uid;
    nativeUserId = null;
    session = TapjoySession(
      setUserIdAndWait: fakeSetUserId,
      currentUserId: () => currentUser,
      nativeUserId: () async => nativeUserId,
      nativeConnected: () async => false,
      connect:
          ({
            required String sdkKey,
            required Map<String, dynamic> options,
            required void Function() onConnectSuccess,
            required void Function(int code, String? message) onConnectFailure,
            required void Function(int code, String? message) onConnectWarning,
          }) async {
            onConnectSuccess();
          },
    );
    TapjoySession.setInstanceForTest(session);
  });

  tearDown(() {
    TapjoySession.setInstanceForTest(TapjoySession());
  });

  /// showAd 는 checkLogin → 세션 직렬화 큐 → connect 대기까지 여러 번의
  /// 이벤트 루프 턴을 거친다. 프레임 하나로는 부족하다.
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await pumpAndIgnoreErrors(tester);
    }
  }

  /// [buildTestApp] 을 쓰는 이유는 ScreenUtil 과 로그인 사용자 때문이다.
  /// `safelyExecute` 의 `startLoading()` 이 띄우는 공용 로딩 인디케이터는
  /// `.w` 로 ScreenUtil 을 읽고, `checkLogin()` 은 `userInfoProvider` 를 읽는다.
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
            // `checkLogin()` 이 첫 read 에서 AsyncLoading 을 보지 않도록, 화면이
            // 먼저 프로필을 구독해 data 까지 해결시킨다.
            ref.watch(userInfoProvider);
            return const SizedBox.shrink();
          },
        ),
        userProfile: UserFactory.create(),
      ),
    );
    // ScreenUtilInit 은 크기를 얻기 전 첫 프레임에 자식을 그리지 않을 수 있다.
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);
    expect(capturedRef.read(userInfoProvider).value, isNotNull);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);
    return _ProbePlatform(capturedRef, capturedContext, 'tapjoy', controller);
  }

  testWidgets('setUserID 성공 전에는 오퍼월을 요청하지 않는다', (tester) async {
    await session.connect(sdkKey: 'sdk-key', initialUserId: uid);
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);

    expect(setCalls, [uid]);
    // 여기서 요청이 나가면 SDK 가 아직 들고 있는 기기 ID 로 오퍼가 생성된다.
    expect(platform.requestedFor, isEmpty);

    gates.single.complete();
    await drain(tester);
    await showing;

    expect(platform.requestedFor, [uid]);
    expect(platform.handledErrors, isEmpty);
    platform.dispose();
  });

  testWidgets('setUserID 실패면 요청하지 않고 실패를 사용자에게 알린다', (tester) async {
    await session.connect(sdkKey: 'sdk-key', initialUserId: uid);
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    gates.single.completeError(
      const TapjoySessionException('SET_USER_ID_FAILED'),
    );
    await drain(tester);
    await showing;

    expect(platform.requestedFor, isEmpty);
    expect(platform.handledErrors.single, isA<TapjoySessionException>());
    platform.dispose();
  });

  testWidgets('요청 직전 계정이 바뀌면 오퍼월을 열지 않는다', (tester) async {
    await session.connect(sdkKey: 'sdk-key', initialUserId: uid);
    final platform = await buildPlatform(tester);

    final showing = platform.showAd();
    await drain(tester);
    // setUserID 성공 이벤트를 기다리는 사이 계정이 바뀐 상황.
    currentUser = 'other-user-id-002';
    gates.single.complete();
    await drain(tester);
    await showing;

    expect(platform.requestedFor, isEmpty);
    expect(platform.handledErrors.single, isA<TapjoySessionException>());
    platform.dispose();
  });

  testWidgets('연타해도 SDK 사용자 ID 설정은 겹치지 않는다', (tester) async {
    await session.connect(sdkKey: 'sdk-key', initialUserId: uid);
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    final second = platform.showAd();
    await drain(tester);

    // Tapjoy 의 setUserID 성공/실패 리스너는 static 단일 슬롯이라 두 번 겹치면
    // 나중 호출이 앞선 호출의 콜백을 덮어쓴다.
    expect(setCalls, [uid]);

    gates.single.complete();
    await drain(tester);
    await first;
    await second;

    expect(platform.requestedFor, [uid, uid]);
    platform.dispose();
  });
}
