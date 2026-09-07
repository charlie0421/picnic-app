import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart';

/// `AdSessionGuard` 를 단위 테스트하는 것만으로는 **배선이 고정되지 않는다** —
/// `showAd()` 에서 `_session.run` 호출을 지우거나 `safelyExecute` 뒤로 옮겨도
/// 가드 자체의 테스트는 전부 통과한다 (Codex 교차 리뷰 지적, PICNIC-2551).
///
/// 여기서는 실제 [ShortformInternalPlatform.showAd] 를 호출해, 세션이 열려 있는
/// 동안 두 번째 탭이 **광고 세션 자체를 시작하지 못한다**는 것을 고정한다.
/// [ShortformInternalPlatform.runAdSession] 을 덮어써서 네트워크·Navigator·
/// 비디오 플레이어 없이 재진입 경로만 검사한다.
class _GatedPlatform extends ShortformInternalPlatform {
  _GatedPlatform(super.ref, super.context, super.id, super.animationController);

  int sessions = 0;
  final gate = Completer<void>();

  @override
  Future<void> runAdSession() async {
    sessions++;
    await gate.future;
  }
}

void main() {
  Future<_GatedPlatform> buildPlatform(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return _GatedPlatform(
      capturedRef,
      capturedContext,
      'internal',
      AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1),
      ),
    );
  }

  testWidgets('세션이 열려 있는 동안 두 번째 showAd 는 새 세션을 시작하지 않는다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);

    // 연타: 첫 세션이 끝나기 전에 두 번째 탭이 들어온다.
    final first = platform.showAd();
    final second = platform.showAd();
    await tester.pump();

    expect(
      platform.sessions,
      1,
      reason: '두 번째 탭이 두 번째 광고 세션을 열면 두 라우트가 토큰 필드를 공유한다',
    );

    platform.gate.complete();
    await first;
    await second;
  });

  testWidgets('첫 세션이 끝난 뒤의 showAd 는 정상적으로 열린다', (tester) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await tester.pump();
    platform.gate.complete();
    await first;

    // 광고를 보고 나온 뒤 다시 누르는 정상 흐름까지 막으면 안 된다.
    // 두 번째 세션은 gate 가 이미 완료돼 즉시 끝난다.
    await platform.showAd();
    expect(platform.sessions, 2);
  });
}
