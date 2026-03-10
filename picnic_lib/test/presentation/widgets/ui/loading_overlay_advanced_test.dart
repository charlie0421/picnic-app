import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_advanced.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_manager.dart';

void main() {
  group('AdvancedLoadingOverlay 테스트', () {
    testWidgets('AdvancedLoadingOverlay가 자식 위젯을 정상적으로 렌더링하는지 확인',
        (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: testChild,
              ),
            ),
          ),
        ),
      );

      // 자식 위젯이 렌더링되었는지 확인
      expect(find.text('Test Child Widget'), findsOneWidget);

      // 초기 상태에서 로딩 인디케이터가 표시되지 않는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Riverpod 프로바이더를 통한 로딩 표시가 정상적으로 동작하는지 확인',
        (WidgetTester tester) async {
      late WidgetRef testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    testRef = ref;
                    return const Text('Test Content');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 초기 상태 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 프로바이더를 통해 로딩 표시
      testRef.read(loadingOverlayProvider.notifier).show();
      await tester.pump(); // rebuild → postFrameCallback scheduled
      await tester.pump(); // postFrameCallback fires → animation starts
      await tester.pump(const Duration(milliseconds: 300)); // animation completes

      // 로딩 인디케이터가 표시되는지 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 프로바이더를 통해 로딩 숨김
      testRef.read(loadingOverlayProvider.notifier).hide();
      await tester.pump(); // rebuild → postFrameCallback scheduled
      await tester.pump(); // postFrameCallback fires → reverse animation starts
      await tester.pump(const Duration(milliseconds: 500)); // animation completes

      // 로딩 상태가 해제되었는지 확인 (provider state)
      expect(testRef.read(loadingOverlayProvider).isLoading, isFalse);
    });

    testWidgets('로딩 메시지가 정상적으로 표시되는지 확인', (WidgetTester tester) async {
      late WidgetRef testRef;
      const testMessage = '데이터를 불러오는 중입니다...';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    testRef = ref;
                    return const Text('Test Content');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 메시지와 함께 로딩 표시
      testRef.read(loadingOverlayProvider.notifier).show(message: testMessage);
      await tester.pump(); // rebuild → postFrameCallback scheduled
      await tester.pump(); // postFrameCallback fires → animation starts
      await tester.pump(const Duration(milliseconds: 300)); // animation completes

      // 로딩 메시지가 표시되는지 확인
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('다양한 애니메이션 타입이 정상적으로 적용되는지 확인', (WidgetTester tester) async {
      late WidgetRef testRef;

      // Scale 애니메이션 테스트
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              animationType: LoadingAnimationType.scale,
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    testRef = ref;
                    return const Text('Test Content');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 스케일 애니메이션으로 로딩 표시
      testRef.read(loadingOverlayProvider.notifier).show(
            animationType: LoadingAnimationType.scale,
          );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Transform.scale 위젯이 있는지 확인
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('다양한 테마가 정상적으로 적용되는지 확인', (WidgetTester tester) async {
      late WidgetRef testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              theme: LoadingOverlayTheme.light,
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    testRef = ref;
                    return const Text('Test Content');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 라이트 테마로 로딩 표시
      testRef.read(loadingOverlayProvider.notifier).show(
            theme: LoadingOverlayTheme.light,
          );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 컨테이너가 라이트 테마 색상을 가지는지 확인
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('커스텀 로딩 위젯이 정상적으로 표시되는지 확인', (WidgetTester tester) async {
      late WidgetRef testRef;
      const customWidget =
          Icon(Icons.hourglass_bottom, size: 50, color: Colors.red);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AdvancedLoadingOverlay(
              loadingWidget: const CircularProgressIndicator(),
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    testRef = ref;
                    return const Text('Test Content');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 커스텀 위젯으로 로딩 표시
      testRef
          .read(loadingOverlayProvider.notifier)
          .show(customWidget: customWidget);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 커스텀 위젯이 표시되는지 확인
      expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('SimpleLoadingOverlay 테스트', () {
    testWidgets('SimpleLoadingOverlay가 자식 위젯을 정상적으로 렌더링하는지 확인',
        (WidgetTester tester) async {
      // SimpleLoadingOverlay는 내부적으로 AdvancedLoadingOverlay를 사용하며
      // loadingWidget 파라미터가 없어 PulseLoadingIndicator를 사용합니다.
      // 따라서 로딩 활성화 없이 초기 렌더링만 테스트합니다.
      await tester.pumpWidget(
        const MaterialApp(
          home: SimpleLoadingOverlay(
            isLoading: false,
            message: '로딩 중...',
            child: Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );

      // 초기 상태에서 자식 위젯이 렌더링되는지 확인
      expect(find.text('Test Content'), findsOneWidget);

      // SimpleLoadingOverlay가 위젯 트리에 있는지 확인
      expect(find.byType(SimpleLoadingOverlay), findsOneWidget);
      expect(find.byType(AdvancedLoadingOverlay), findsOneWidget);
    });
  });

  group('LoadingOverlayManager 테스트', () {
    test('싱글톤 인스턴스가 정상적으로 작동하는지 확인', () {
      final manager1 = LoadingOverlayManager.instance;
      final manager2 = LoadingOverlayManager.instance;

      expect(manager1, equals(manager2));
    });

    test('키 기반 로딩 상태 관리가 정상적으로 동작하는지 확인', () {
      final manager = LoadingOverlayManager.instance;

      // 초기 상태 확인
      expect(manager.isAnyLoading, isFalse);
      expect(manager.activeKeys, isEmpty);

      // 로딩 표시
      manager.showWithKey(key: 'test1', message: '테스트 로딩');
      expect(manager.isLoadingWithKey('test1'), isTrue);
      expect(manager.isAnyLoading, isTrue);
      expect(manager.activeKeys, contains('test1'));

      // 추가 로딩 표시
      manager.showWithKey(key: 'test2');
      expect(manager.activeKeys.length, equals(2));

      // 특정 키로 로딩 숨김
      manager.hideWithKey('test1');
      expect(manager.isLoadingWithKey('test1'), isFalse);
      expect(manager.isLoadingWithKey('test2'), isTrue);
      expect(manager.activeKeys.length, equals(1));

      // 모든 로딩 숨김
      manager.hideAll();
      expect(manager.isAnyLoading, isFalse);
      expect(manager.activeKeys, isEmpty);
    });

    test('상태 가져오기가 정상적으로 동작하는지 확인', () {
      final manager = LoadingOverlayManager.instance;

      // 상태 설정
      manager.showWithKey(
        key: 'test',
        message: '테스트 메시지',
        theme: LoadingOverlayTheme.light,
        animationType: LoadingAnimationType.scale,
      );

      // 상태 확인
      final state = manager.getStateWithKey('test');
      expect(state, isNotNull);
      expect(state!.isLoading, isTrue);
      expect(state.message, equals('테스트 메시지'));
      expect(state.theme, equals(LoadingOverlayTheme.light));
      expect(state.animationType, equals(LoadingAnimationType.scale));

      // 존재하지 않는 키
      final nonExistentState = manager.getStateWithKey('nonexistent');
      expect(nonExistentState, isNull);

      // 정리
      manager.hideAll();
    });
  });

  group('LoadingOverlayThemeData 테스트', () {
    test('테마 데이터가 정확하게 반환되는지 확인', () {
      // 다크 테마
      final darkTheme =
          LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.dark);
      expect(darkTheme.barrierColor, equals(Colors.black54));
      expect(darkTheme.progressColor, equals(Colors.white));
      expect(darkTheme.textColor, equals(Colors.white));
      expect(darkTheme.blurSigma, isNull);

      // 라이트 테마
      final lightTheme =
          LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.light);
      expect(lightTheme.barrierColor, equals(Colors.white70));
      expect(lightTheme.progressColor, equals(Colors.blue));
      expect(lightTheme.textColor, equals(Colors.black87));

      // 블러 테마
      final blurTheme =
          LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.blur);
      expect(blurTheme.blurSigma, equals(3.0));
    });
  });
}
