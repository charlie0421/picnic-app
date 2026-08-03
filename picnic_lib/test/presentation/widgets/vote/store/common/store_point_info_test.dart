import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('StorePointInfo - logged out (no supabase)', () {
    testWidgets('renders with title and login prompt', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Test Title',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      // Widget rendered
      expect(find.byType(StorePointInfo), findsOneWidget);

      expect(find.text('Test Title'), findsOneWidget);

      // UnderlinedText for policy guide
      expect(find.byType(UnderlinedText), findsWidgets);
    });

    testWidgets('uses content height and does not overflow a compact request', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(title: 'Star Candy', width: 200, height: 100),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with custom topMargin and titlePadding', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Custom',
            width: 300,
            height: 150,
            topMargin: 10,
            titlePadding: 8,
          ),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });

    testWidgets('renders with default constructor values', (tester) async {
      // 격리 — 이 테스트 하나에만 적용된다.
      //
      // StorePointInfo 의 기본값 `width: 48` 은 좌우 패딩 14+14 를 빼면 내용에
      // 20px 만 남아 Row 가 가로로 119px 넘친다. 다만 실제 호출부 두 곳
      // (store_page.dart / star_candy_store.dart)은 모두 `width: double.infinity`
      // 를 넘기므로 이 기본값은 사용자에게 도달하지 않는 죽은 값이다. 공개 위젯의
      // 기본값을 바꾸는 건 제품 판단이라 여기서 안 고친다.
      //
      // 파일 단위로 걸면 바로 위 'does not overflow a compact request' 의
      // 오버플로 검사(`expect(tester.takeException(), isNull)`)까지 무력화된다.
      // 그래서 기본값을 쓰는 이 테스트에만 붙인다.
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const StorePointInfo(title: 'Default'), loggedIn: false),
        knownDefects: const ['A RenderFlex overflowed by'],
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });
  });

  group('StorePointInfo - logged in with mock supabase', () {
    setUp(() async {
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
    });

    testWidgets('shows StarCandyInfoText when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Star Candy Pouch',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });

    testWidgets('shows policy guide when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Star Candy Pouch',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(UnderlinedText), findsWidgets);
    });
  });

  group('StorePointInfo properties', () {
    test('can be instantiated with required params', () {
      const widget = StorePointInfo(title: 'Test');
      expect(widget.title, 'Test');
      expect(widget.width, 48);
      expect(widget.height, 36);
      expect(widget.topMargin, 0);
      expect(widget.titlePadding, isNull);
    });

    test('can be instantiated with all params', () {
      const widget = StorePointInfo(
        title: 'Full',
        width: 100,
        height: 200,
        topMargin: 30,
        titlePadding: 12,
      );
      expect(widget.title, 'Full');
      expect(widget.width, 100);
      expect(widget.height, 200);
      expect(widget.topMargin, 30);
      expect(widget.titlePadding, 12);
    });
  });

  testWidgets('default top margin adds no space before the pouch', (
    WidgetTester tester,
  ) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Column(
          children: const [
            Text('previous section'),
            StorePointInfo(
              title: 'Star Candy',
              width: double.infinity,
              height: 120,
            ),
          ],
        ),
        loggedIn: false,
      ),
    );
    await pumpAndIgnoreErrors(tester);

    final previousRect = tester.getRect(find.text('previous section'));
    final pouchRect = tester.getRect(find.byType(StorePointInfo));

    expect(pouchRect.top - previousRect.bottom, 0);
  });

  testWidgets('새로고침 버튼은 파우치 카드 안에 렌더링된다', (WidgetTester tester) async {
    var taps = 0;
    await tester.pumpWidget(
      buildTestAppPage(
        StorePointInfo(
          title: '별사탕 파우치',
          width: double.infinity,
          refreshButton: GestureDetector(
            key: const Key('pouch-refresh'),
            onTap: () => taps++,
            child: const Icon(Icons.refresh),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 카드(StorePointInfo) 하위 트리에 있어야 한다 — 스토어 헤더가 아니라.
    expect(
      find.descendant(
        of: find.byType(StorePointInfo),
        matching: find.byKey(const Key('pouch-refresh')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pouch-refresh')));
    expect(taps, 1);
  });

  testWidgets('공통 파우치가 새로고침 동작을 직접 제공한다', (WidgetTester tester) async {
    var taps = 0;
    await tester.pumpWidget(
      buildTestAppPage(
        StorePointInfo(
          title: '별사탕 파우치',
          width: double.infinity,
          onRefresh: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('store-point-info-refresh')), findsOneWidget);
    await tester.tap(find.byKey(const Key('store-point-info-refresh')));
    expect(taps, 1);
  });
}
