import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart';

void main() {
  testWidgets('dispose 는 모든 플랫폼을 dispose 한다', (tester) async {
    // 프로덕션 결함 (PICNIC-APP-5G9): dispose 가 _platforms.clear() 만 하고
    // 각 플랫폼의 dispose() 를 호출하지 않아, PanglePlatform 의 pollingSignals
    // 구독이 페이지 unmount 후에도 살아남아 dispose 된 ref 를 계속 읽었다.
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
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    final service = AdService(
      ref: capturedRef,
      context: capturedContext,
      animationController: controller,
    );
    final platforms = [
      for (final id in [
        'admob',
        'pangle',
        'tapjoy',
        'pincrux',
        'internal-shortform',
      ])
        service.getPlatform(id)!,
    ];
    service.dispose();
    for (final platform in platforms) {
      expect(platform.isDisposed, isTrue, reason: platform.id);
    }
    controller.dispose();
  });

  testWidgets('dispose 는 진행 중이던 로딩 오버레이를 내린다', (tester) async {
    // AdPlatform.dispose 는 _isDisposed 를 먼저 세워 stopAllAnimations 경로가
    // 전부 no-op 이었다. 로딩 오버레이는 전역이라 페이지가 죽어도 남는다.
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
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    final service = AdService(
      ref: capturedRef,
      context: capturedContext,
      animationController: controller,
    );
    service.getPlatform('pangle')!.startLoading();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.dispose();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // 전역 로딩 상태도 함께 해제돼야 다음 방문의 버튼이 잠기지 않는다.
    expect(
      capturedRef.read(adLoadingStateProvider)['pangle'],
      isNot(isTrue),
    );
    controller.dispose();
  });

  testWidgets('dispose 는 자신이 켜지 않은 오버레이는 건드리지 않는다', (tester) async {
    // OverlayLoadingProgress 는 전역 싱글턴이다. 플랫폼이 켠 적 없는
    // 오버레이(다른 기능 소유)를 dispose 가 닫아 버리면 안 된다.
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
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    final service = AdService(
      ref: capturedRef,
      context: capturedContext,
      animationController: controller,
    );
    OverlayLoadingProgress.start(capturedContext); // 다른 기능의 오버레이
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.dispose();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    OverlayLoadingProgress.stop();
    controller.dispose();
  });
}
