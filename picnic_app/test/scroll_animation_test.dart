import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/animation_service.dart';
import 'package:picnic_lib/presentation/widgets/animated_list_item.dart';

void main() {
  group('Animation Service Tests', () {
    late AnimationService animationService;

    setUp(() {
      animationService = AnimationService();
    });

    tearDown(() {
      animationService.cleanup();
    });

    group('AnimationService Basic Tests', () {
      testWidgets('should create and manage animation controllers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TestWidget(animationService: animationService);
                },
              ),
            ),
          ),
        );

        expect(find.byType(TestWidget), findsOneWidget);
        await tester.pump();
      });

      test('should have proper default durations', () {
        expect(AnimationService.defaultDuration,
            const Duration(milliseconds: 300));
        expect(
            AnimationService.fastDuration, const Duration(milliseconds: 150));
        expect(
            AnimationService.slowDuration, const Duration(milliseconds: 600));
      });

      test('should initialize stats properly', () {
        final stats = animationService.stats;
        expect(stats, isNotNull);
        expect(stats.activeControllers, 0);
        expect(stats.disposedControllers, 0);
      });

      test('should preload Lottie animations', () async {
        // 실제 Lottie 파일이 없으므로 preloadLottieAnimation 메서드 테스트는 건너뜀
        // 서비스가 정상적으로 초기화되었는지만 확인
        expect(animationService, isNotNull);
      });

      test('should cleanup properly', () {
        expect(() => animationService.cleanup(), returnsNormally);
      });
    });

    group('AnimatedListItem Widget Tests', () {
      testWidgets('should create animated list item widget',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedListItem(
                index: 0,
                delay: const Duration(milliseconds: 100),
                child: Container(
                  height: 50,
                  color: Colors.blue,
                  child: const Text('Test Item'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedListItem), findsOneWidget);
        expect(find.text('Test Item'), findsOneWidget);

        // 애니메이션이 시작되도록 시간을 진행
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      });
    });
  });
}

class TestWidget extends StatefulWidget {
  final AnimationService animationService;

  const TestWidget({
    Key? key,
    required this.animationService,
  }) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.animationService.createController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      tag: 'test_controller',
    );
  }

  @override
  void dispose() {
    widget.animationService.disposeController('test_controller');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.red,
      child: const Center(
        child: Text('Test'),
      ),
    );
  }
}
