import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay.dart';

void main() {
  group('LoadingOverlay 테스트', () {
    testWidgets('LoadingOverlay 위젯이 자식 위젯을 정상적으로 렌더링하는지 확인',
        (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      // 자식 위젯이 렌더링되었는지 확인
      expect(find.text('Test Child Widget'), findsOneWidget);

      // 초기 상태에서 로딩 인디케이터가 표시되지 않는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('show() 호출 시 로딩 오버레이가 표시되는지 확인', (WidgetTester tester) async {
      final overlayKey = GlobalKey<LoadingOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            key: overlayKey,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );

      // 초기 상태 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 로딩 표시
      overlayKey.currentState!.show();
      await tester.pump(); // 상태 변경 적용

      // 로딩 인디케이터가 표시되는지 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hide() 호출 시 로딩 오버레이가 숨겨지는지 확인', (WidgetTester tester) async {
      final overlayKey = GlobalKey<LoadingOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            key: overlayKey,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );

      // 로딩 표시
      overlayKey.currentState!.show();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 로딩 숨김
      overlayKey.currentState!.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // 애니메이션 완료 대기

      // 로딩 인디케이터가 사라졌는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('커스텀 로딩 위젯이 정상적으로 표시되는지 확인', (WidgetTester tester) async {
      final overlayKey = GlobalKey<LoadingOverlayState>();
      const customLoadingWidget = Text('Custom Loading');

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            key: overlayKey,
            loadingWidget: customLoadingWidget,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );

      // 로딩 표시
      overlayKey.currentState!.show();
      await tester.pump();

      // 커스텀 로딩 위젯이 표시되는지 확인
      expect(find.text('Custom Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Context 확장 메서드가 정상적으로 동작하는지 확인', (WidgetTester tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  testContext = context;
                  return const Text('Test Content');
                },
              ),
            ),
          ),
        ),
      );

      // 초기 상태 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(testContext.isLoadingOverlayVisible, isFalse);

      // Context 확장으로 로딩 표시
      testContext.showLoading();
      await tester.pump();

      // 로딩 상태 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(testContext.isLoadingOverlayVisible, isTrue);

      // Context 확장으로 로딩 숨김
      testContext.hideLoading();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 로딩이 사라졌는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(testContext.isLoadingOverlayVisible, isFalse);
    });

    testWidgets('barrierDismissible이 true일 때 배경 터치로 오버레이가 해제되는지 확인',
        (WidgetTester tester) async {
      final overlayKey = GlobalKey<LoadingOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            key: overlayKey,
            barrierDismissible: true,
            child: const Scaffold(
              body: Text('Test Content'),
            ),
          ),
        ),
      );

      // 로딩 표시
      overlayKey.currentState!.show();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 배경 터치
      await tester.tap(find.byType(Container).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 로딩이 해제되었는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
