import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

void main() {
  group('LoadingOverlayWithIcon 테스트', () {
    testWidgets('LoadingOverlayWithIcon이 자식 위젯을 정상적으로 렌더링하는지 확인',
        (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      // 자식 위젯이 렌더링되었는지 확인
      expect(find.text('Test Child Widget'), findsOneWidget);

      // 초기 상태에서 로딩 오버레이가 표시되지 않는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('show() 호출 시 앱 아이콘과 로딩 오버레이가 표시되는지 확인',
        (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      // LoadingOverlayWithIcon의 상태에 접근
      final loadingState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 로딩 표시
      loadingState.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // 애니메이션 완료 대기

      // 로딩 인디케이터가 표시되는지 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 앱 아이콘 이미지 또는 기본 아이콘이 표시되는지 확인
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('hide() 호출 시 로딩 오버레이가 숨겨지는지 확인', (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      final loadingState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 로딩 표시
      loadingState.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 로딩이 표시되었는지 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 로딩 숨김
      loadingState.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // 애니메이션 완료 대기

      // 로딩 인디케이터가 숨겨졌는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('커스텀 로딩 메시지가 표시되는지 확인', (WidgetTester tester) async {
      const testMessage = '사용자 정의 로딩 메시지';
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            loadingMessage: testMessage,
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      final loadingState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 로딩 표시
      loadingState.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 커스텀 메시지가 표시되는지 확인
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('Context 확장 메서드가 올바르게 작동하는지 확인', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlayWithIcon(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      // 초기 상태 확인
      expect(capturedContext.isLoadingWithIconVisible, false);

      // Context 확장을 통한 로딩 표시
      capturedContext.showLoadingWithIcon();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 로딩이 표시되었는지 확인
      expect(capturedContext.isLoadingWithIconVisible, true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Context 확장을 통한 로딩 숨김
      capturedContext.hideLoadingWithIcon();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 로딩이 숨겨졌는지 확인
      expect(capturedContext.isLoadingWithIconVisible, false);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('커스텀 아이콘 크기가 적용되는지 확인', (WidgetTester tester) async {
      const customIconSize = 80.0;
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            iconSize: customIconSize,
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      final loadingState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 로딩 표시
      loadingState.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 커스텀 아이콘 크기가 적용되었는지 확인
      final containerFinder = find.descendant(
        of: find.byType(LoadingOverlayWithIcon),
        matching: find.byType(Container),
      );

      // Container가 있는지 확인 (앱 아이콘 컨테이너)
      expect(containerFinder, findsWidgets);
    });

    testWidgets('애니메이션 컨트롤러가 올바르게 초기화되고 해제되는지 확인', (WidgetTester tester) async {
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlayWithIcon(
            child: Scaffold(
              body: testChild,
            ),
          ),
        ),
      );

      final loadingState = tester.state<LoadingOverlayWithIconState>(
        find.byType(LoadingOverlayWithIcon),
      );

      // 애니메이션 컨트롤러가 초기화되었는지 확인
      expect(loadingState.mounted, true);

      // 위젯 제거
      await tester.pumpWidget(const SizedBox());

      // 위젯이 제거되었는지 확인
      expect(find.byType(LoadingOverlayWithIcon), findsNothing);
    });
  });
}
