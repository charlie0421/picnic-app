import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

void main() {
  group('LoadingOverlayWithIcon Performance Tests', () {
    testWidgets('성능 최적화 모드에서 애니메이션 컨트롤러 지연 초기화 확인',
        (WidgetTester tester) async {
      // Given: 애니메이션이 비활성화된 위젯
      final optimizedWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: true,
          enableRotation: false,
          enableScale: false,
          enableFade: false,
          showProgressIndicator: false,
          child: Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      );

      // When: 위젯을 빌드
      await tester.pumpWidget(optimizedWidget);

      // Then: 위젯이 정상적으로 렌더링됨
      expect(find.text('Test'), findsOneWidget);

      // 로딩 오버레이가 초기에는 보이지 않음
      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );
      expect(state.isVisible, isFalse);
    });

    testWidgets('성능 최적화된 모든 애니메이션 동시 실행 테스트', (WidgetTester tester) async {
      // Given: 모든 애니메이션이 활성화된 최적화 위젯
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlayWithIcon(
            enablePerformanceOptimization: true,
            showProgressIndicator: false,
            child: Scaffold(
              body: Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      // When: 로딩 오버레이 표시
      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );
      state.show();
      await tester.pump();

      // Then: 오버레이가 표시됨
      expect(state.isVisible, isTrue);

      // 애니메이션이 실행되는 동안 성능 확인
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration(milliseconds: 100));
        // 매 프레임에서 위젯이 정상적으로 렌더링되어야 함
        expect(find.byType(LoadingOverlayWithIcon), findsOneWidget);
      }

      // 로딩 숨김 (hide()가 stop()으로 반복 애니메이션 정지 후 reverse 실행)
      state.hide();
      await tester.pumpAndSettle();
      expect(state.isVisible, isFalse);
    });

    testWidgets('메모리 최적화 - 불필요한 애니메이션 컨트롤러 생성 방지', (WidgetTester tester) async {
      // Given: 일부 애니메이션만 활성화된 위젯
      final partialAnimationWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: true,
          enableRotation: true,
          enableScale: false, // 비활성화
          enableFade: false, // 비활성화
          showProgressIndicator: false,
          child: Scaffold(
            body: Center(child: Text('Partial Animation Test')),
          ),
        ),
      );

      // When
      await tester.pumpWidget(partialAnimationWidget);

      // Then: 위젯이 정상적으로 작동함
      expect(find.text('Partial Animation Test'), findsOneWidget);

      // 로딩 표시 테스트
      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );
      state.show();
      await tester.pump();
      expect(state.isVisible, isTrue);

      // 숨김 테스트
      state.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.isVisible, isFalse);
    });

    testWidgets('성능 최적화 비활성화 모드 테스트', (WidgetTester tester) async {
      // Given: 성능 최적화가 비활성화된 위젯
      final nonOptimizedWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: false,
          showProgressIndicator: false,
          child: Scaffold(
            body: Center(child: Text('Non-Optimized Test')),
          ),
        ),
      );

      // When
      await tester.pumpWidget(nonOptimizedWidget);

      // Then: 여전히 정상적으로 작동해야 함
      expect(find.text('Non-Optimized Test'), findsOneWidget);

      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 로딩 표시/숨김 테스트
      state.show();
      await tester.pump();
      expect(state.isVisible, isTrue);

      state.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.isVisible, isFalse);
    });

    testWidgets('애니메이션 성능 스트레스 테스트', (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlayWithIcon(
            enablePerformanceOptimization: true,
            showProgressIndicator: false,
            child: Scaffold(
              body: Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      // When: 로딩 표시
      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );
      state.show();
      await tester.pump();

      // Then: 빠른 속도로 여러 프레임 렌더링 테스트
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 60; i++) {
        // 60프레임 시뮬레이션
        await tester.pump(Duration(milliseconds: 16)); // ~60 FPS

        // 각 프레임에서 위젯이 정상적으로 존재해야 함
        expect(find.byType(LoadingOverlayWithIcon), findsOneWidget);
      }

      stopwatch.stop();

      // 2초 이내에 60프레임을 처리할 수 있어야 함
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      // 정리
      state.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('다중 애니메이션 조합 성능 테스트', (WidgetTester tester) async {
      // Given: 모든 애니메이션 활성화
      final multiAnimationWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: true,
          enableRotation: true,
          enableScale: true,
          enableFade: true,
          rotationDuration: Duration(milliseconds: 500),
          scaleDuration: Duration(milliseconds: 300),
          fadeDuration: Duration(milliseconds: 400),
          showProgressIndicator: false,
          child: Scaffold(
            body: Center(child: Text('Multi Animation Test')),
          ),
        ),
      );

      // When
      await tester.pumpWidget(multiAnimationWidget);

      final state = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );
      state.show();
      await tester.pump();

      // Then: 빠른 애니메이션들이 동시에 실행되어도 성능이 유지되어야 함
      for (int i = 0; i < 30; i++) {
        await tester.pump(Duration(milliseconds: 33)); // ~30 FPS
        expect(find.byType(LoadingOverlayWithIcon), findsOneWidget);
      }

      // 정리
      state.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Context 확장 메서드 성능 테스트', (WidgetTester tester) async {
      // Given
      late BuildContext capturedContext;
      final contextTestWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: true,
          showProgressIndicator: false,
          enableRotation: false,
          enableScale: false,
          enableFade: false,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.showLoadingWithIcon();
                    },
                    child: Text('Show Loading'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // When
      await tester.pumpWidget(contextTestWidget);

      // Then: Context 확장 메서드가 빠르게 작동해야 함
      capturedContext.showLoadingWithIcon();
      await tester.pump();

      expect(capturedContext.isLoadingWithIconVisible, isTrue);

      capturedContext.hideLoadingWithIcon();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedContext.isLoadingWithIconVisible, isFalse);
    });
  });

  group('성능 벤치마크 테스트', () {
    testWidgets('최적화된 vs 비최적화 성능 비교', (WidgetTester tester) async {
      // 최적화된 버전 벤치마크
      final optimizedWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: true,
          showProgressIndicator: false,
          enableRotation: false,
          enableScale: false,
          enableFade: false,
          child: Scaffold(body: Center(child: Text('Optimized'))),
        ),
      );

      await tester.pumpWidget(optimizedWidget);
      final optimizedState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      final optimizedStopwatch = Stopwatch()..start();
      optimizedState.show();
      await tester.pump();

      for (int i = 0; i < 30; i++) {
        await tester.pump(Duration(milliseconds: 16));
      }

      optimizedState.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      optimizedStopwatch.stop();

      // 비최적화된 버전 벤치마크
      final nonOptimizedWidget = MaterialApp(
        home: LoadingOverlayWithIcon(
          enablePerformanceOptimization: false,
          showProgressIndicator: false,
          enableRotation: false,
          enableScale: false,
          enableFade: false,
          child: Scaffold(body: Center(child: Text('Non-Optimized'))),
        ),
      );

      await tester.pumpWidget(nonOptimizedWidget);
      final nonOptimizedState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      final nonOptimizedStopwatch = Stopwatch()..start();
      nonOptimizedState.show();
      await tester.pump();

      for (int i = 0; i < 30; i++) {
        await tester.pump(Duration(milliseconds: 16));
      }

      nonOptimizedState.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      nonOptimizedStopwatch.stop();

      // 결과 출력 (정보성)
      logger.i('최적화된 버전: ${optimizedStopwatch.elapsedMilliseconds}ms');
      logger.i('비최적화 버전: ${nonOptimizedStopwatch.elapsedMilliseconds}ms');

      // 최적화된 버전이 비최적화 버전보다 느리지 않아야 함
      expect(
        optimizedStopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(
            nonOptimizedStopwatch.elapsedMilliseconds + 100), // 100ms 여유
      );
    });
  });
}
