import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/ui/search_results_list.dart';

import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(loadTestFonts);

  setUp(() {
    initTestColors();
  });

  group('SearchResultsList', () {
    testWidgets('renders items with itemBuilder', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: items,
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchResultsList<String>), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('shows empty view when items is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    });

    testWidgets('shows custom empty message', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
              emptyMessage: 'No results found',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('shows error view with default message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
              hasError: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('검색 중 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('shows error view with custom message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
              hasError: true,
              errorMessage: 'Custom error',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom error'), findsOneWidget);
    });

    testWidgets('shows retry button when hasError and onRetry provided', (
      WidgetTester tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
              hasError: true,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(retried, isTrue);
    });

    testWidgets('320px 200% error feedback stays readable with a 48px retry', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      addTearDown(tester.view.reset);
      var retried = false;
      const message = '검색 결과를 불러오지 못했습니다. 네트워크 상태를 확인해 주세요.';

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 280,
            child: SearchResultsList<String>(
              items: const [],
              itemBuilder: (context, item, index) => Text(item),
              hasError: true,
              errorMessage: message,
              onRetry: () => retried = true,
            ),
          ),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final messageText = tester.widget<Text>(find.text(message));
      expect(messageText.style?.fontFamily, 'packages/picnic_lib/Pretendard');
      expect(messageText.style?.fontSize, 14);
      expect(messageText.style?.height, 1.45);

      final retryTarget = find.ancestor(
        of: find.text('다시 시도'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      expect(retryTarget, findsOneWidget);
      expect(tester.getSize(retryTarget).height, greaterThanOrEqualTo(48));
      await tester.tap(retryTarget);
      expect(retried, isTrue);
    });

    testWidgets(
      'does not show retry button when hasError but onRetry is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              height: 400,
              child: SearchResultsList<String>(
                items: const [],
                itemBuilder: (context, item, index) => Text(item),
                hasError: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byType(OutlinedButton), findsNothing);
      },
    );

    testWidgets(
      'shows loading view when isLoading is true and items is empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              height: 400,
              child: SearchResultsList<String>(
                items: const [],
                itemBuilder: (context, item, index) => Text(item),
                isLoading: true,
              ),
            ),
          ),
        );
        // PulseLoadingIndicator uses Image.asset which fails in test env
        tester.takeException();
        await tester.pump();
        tester.takeException();

        expect(find.text('검색 중...'), findsOneWidget);
        expect(find.byType(MediumPulseLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'shows results list (not loading view) when isLoading but items exist',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              height: 400,
              child: SearchResultsList<String>(
                items: const ['A', 'B'],
                itemBuilder: (context, item, index) => Text(item),
                isLoading: true,
                hasMore: true,
              ),
            ),
          ),
        );
        tester.takeException();
        await tester.pump();
        tester.takeException();

        // Items should be visible
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        // Loading indicator at bottom (load more)
        expect(find.byType(SmallPulseLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('calls onLoadMore when scrolled to bottom', (
      WidgetTester tester,
    ) async {
      bool loadMoreCalled = false;
      final items = List.generate(20, (i) => 'Item $i');

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: items,
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 80, child: Text(item)),
              hasMore: true,
              onLoadMore: () => loadMoreCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Scroll to the bottom to trigger onLoadMore
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);

      // Fling to scroll to the end
      await tester.fling(listFinder, const Offset(0, -5000), 1000);
      await tester.pumpAndSettle();

      expect(loadMoreCalled, isTrue);
    });

    testWidgets('does not call onLoadMore when hasMore is false', (
      WidgetTester tester,
    ) async {
      bool loadMoreCalled = false;
      final items = List.generate(20, (i) => 'Item $i');

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: items,
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 80, child: Text(item)),
              hasMore: false,
              onLoadMore: () => loadMoreCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      final listFinder = find.byType(ListView);
      await tester.fling(listFinder, const Offset(0, -5000), 1000);
      await tester.pumpAndSettle();

      expect(loadMoreCalled, isFalse);
    });

    testWidgets('does not call onLoadMore when isLoading is true', (
      WidgetTester tester,
    ) async {
      bool loadMoreCalled = false;
      final items = List.generate(20, (i) => 'Item $i');

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: SearchResultsList<String>(
              items: items,
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 80, child: Text(item)),
              hasMore: true,
              isLoading: true,
              onLoadMore: () => loadMoreCalled = true,
            ),
          ),
        ),
      );
      tester.takeException();
      await tester.pump();
      tester.takeException();

      final listFinder = find.byType(ListView);
      await tester.fling(listFinder, const Offset(0, -5000), 1000);
      // Use pump with duration instead of pumpAndSettle to avoid
      // timeout from PulseLoadingIndicator's repeating animation
      await tester.pump(const Duration(seconds: 1));
      tester.takeException();
      await tester.pump(const Duration(seconds: 1));
      tester.takeException();

      expect(loadMoreCalled, isFalse);
    });
  });

  group('SearchResultCard', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const SearchResultCard(child: Text('Card content'))),
      );
      await tester.pump();

      expect(find.byType(SearchResultCard), findsOneWidget);
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('handles tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          SearchResultCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });
  });
}
