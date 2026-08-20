import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
