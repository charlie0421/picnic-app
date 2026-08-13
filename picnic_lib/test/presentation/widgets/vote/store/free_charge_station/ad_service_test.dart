import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/test_app.dart';

/// BLOCKER-3 반례 재현용 fake — 실제 SDK 를 건드리지 않고 dispose() 호출
/// 여부만 관찰한다.
class _FakeAdPlatform extends AdPlatform {
  _FakeAdPlatform(
    super.ref,
    super.context,
    super.id, [
    super.animationController,
  ]);

  bool disposeCalled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showAd() async {}

  @override
  Future<void> handleError(dynamic error, StackTrace? stackTrace) async {}

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }
}

/// AdPlatform 생성에 필요한 실제 WidgetRef/BuildContext/AnimationController 를
/// 얻기 위한 최소 호스트 위젯 — TickerProviderStateMixin 이 vsync 를 제공한다.
class _AnimationHost extends StatefulWidget {
  final Widget Function(AnimationController controller) builder;

  const _AnimationHost({required this.builder});

  @override
  State<_AnimationHost> createState() => _AnimationHostState();
}

class _AnimationHostState extends State<_AnimationHost>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
  });

  group('AdService.dispose (BLOCKER-3)', () {
    testWidgets(
        '등록된 모든 AdPlatform.dispose() 를 호출한 뒤에야 플랫폼 목록을 비운다',
        (tester) async {
      late WidgetRef capturedRef;
      late BuildContext capturedContext;
      late AnimationController capturedController;

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          _AnimationHost(
            builder: (controller) => Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                capturedController = controller;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      final fake1 = _FakeAdPlatform(
          capturedRef, capturedContext, 'fake1', capturedController);
      final fake2 = _FakeAdPlatform(
          capturedRef, capturedContext, 'fake2', capturedController);

      final service = AdService(
        ref: capturedRef,
        context: capturedContext,
        animationController: capturedController,
        platformsOverride: {'fake1': fake1, 'fake2': fake2},
      );

      // 수정 전(clear() 만 하던 시절)에는 아래 두 dispose 호출이 전혀
      // 일어나지 않아, flow 의 워치독 타이머·pendingAd 가 위젯 teardown
      // 이후에도 살아남았다(BLOCKER-3: free_charge_station.dart 에서 dispose
      // 된 AnimationController 를 나중에 건드리거나 광고가 누수됨).
      expect(fake1.disposeCalled, isFalse);
      expect(fake2.disposeCalled, isFalse);

      service.dispose();

      expect(fake1.disposeCalled, isTrue);
      expect(fake2.disposeCalled, isTrue);
      expect(fake1.isDisposed, isTrue);
      expect(fake2.isDisposed, isTrue);
      expect(service.getPlatform('fake1'), isNull);
      expect(service.getPlatform('fake2'), isNull);
    });
  });
}
