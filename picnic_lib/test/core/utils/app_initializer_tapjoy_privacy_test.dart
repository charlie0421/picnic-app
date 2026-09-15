import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';

/// PICNIC-2682 (major-I).
///
/// `TJPrivacyPolicy` 의 setter 네 개는 모두 `Future<void>` 이고 각각
/// MethodChannel 호출이다(tapjoy_privacy_policy.dart:21,41,61,81). 이걸 await
/// 하지 않으면 connect 확정 hook 이 **설정이 적용되기 전에** 성공으로 캐시되고,
/// 채널 오류도 hook 의 오류 처리를 그냥 빠져나간다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tapjoy_offerwall');
  const privacyMethods = <String>[
    'setSubjectToGDPR',
    'setUserConsent',
    'setBelowConsentAge',
    'setUSPrivacy',
  ];

  late TestDefaultBinaryMessenger messenger;
  late List<String> calls;

  /// 이 메서드는 게이트가 열릴 때까지 응답하지 않는다.
  String? gatedMethod;
  late Completer<void> gate;

  /// 이 메서드는 PlatformException 을 던진다.
  String? failingMethod;

  setUp(() {
    calls = <String>[];
    gatedMethod = null;
    failingMethod = null;
    gate = Completer<void>();
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == failingMethod) {
        throw PlatformException(code: 'ERROR', message: 'channel failed');
      }
      if (call.method == gatedMethod) await gate.future;
      return null;
    });
  });

  tearDown(() {
    if (!gate.isCompleted) gate.complete();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('네 설정이 실제로 적용된 뒤에야 완료된다', (tester) async {
    // 게이트는 테스트 본문 zone 에서 만든다 — setUp zone 의 Future 는
    // FakeAsync 가 돌려주지 않아 pump 로 풀리지 않는다.
    gate = Completer<void>();
    gatedMethod = 'setUSPrivacy';

    var applied = false;
    final pending = AppInitializer.applyTapjoyPrivacySettings().then((_) {
      applied = true;
    });

    await tester.pump();
    expect(calls, containsAll(privacyMethods), reason: '네 설정 모두 전송돼야 한다');

    expect(applied, isFalse, reason: '적용 전에 완료되면 hook 이 성공으로 캐시돼 오퍼월이 먼저 열린다');

    gate.complete();
    await tester.pump();
    await pending;
    expect(applied, isTrue);
  });

  testWidgets('채널 오류는 밖으로 새지 않고 나머지 설정도 계속 적용된다', (tester) async {
    failingMethod = 'setSubjectToGDPR';

    await AppInitializer.applyTapjoyPrivacySettings();
    await tester.pump();

    expect(
      calls,
      containsAll(privacyMethods),
      reason: '하나가 실패해도 나머지 설정은 적용해야 한다',
    );
  });
}
