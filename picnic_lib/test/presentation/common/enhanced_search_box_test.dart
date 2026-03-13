import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('SearchState', () {
    test('creates with defaults', () {
      const state = SearchState();
      expect(state.query, '');
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.errorMessage, null);
    });

    test('creates with custom values', () {
      const state = SearchState(
        query: 'test',
        isLoading: true,
        hasError: false,
      );
      expect(state.query, 'test');
      expect(state.isLoading, true);
    });

    test('copyWith preserves values', () {
      const state = SearchState(query: 'original');
      final copy = state.copyWith(isLoading: true);
      expect(copy.query, 'original');
      expect(copy.isLoading, true);
    });

    test('copyWith updates values', () {
      const state = SearchState(query: 'old');
      final copy = state.copyWith(query: 'new');
      expect(copy.query, 'new');
    });

    test('equality', () {
      const state1 = SearchState(query: 'test');
      const state2 = SearchState(query: 'test');
      const state3 = SearchState(query: 'other');
      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('hashCode consistency', () {
      const state1 = SearchState(query: 'test');
      const state2 = SearchState(query: 'test');
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('copyWith with error', () {
      const state = SearchState();
      final copy = state.copyWith(
        hasError: true,
        errorMessage: 'Network error',
      );
      expect(copy.hasError, true);
      expect(copy.errorMessage, 'Network error');
    });
  });

  group('EnhancedSearchBox', () {
    testWidgets('renders with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const EnhancedSearchBox(hintText: 'Search here'),
        ),
      );
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders with initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const EnhancedSearchBox(
            hintText: 'Search',
            initialValue: 'BTS',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BTS'), findsOneWidget);
    });

    testWidgets('renders disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const EnhancedSearchBox(
            hintText: 'Disabled',
            enabled: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });

    testWidgets('renders without search icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const EnhancedSearchBox(
            hintText: 'No icon',
            showSearchIcon: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });

    testWidgets('renders with custom height', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const EnhancedSearchBox(
            hintText: 'Tall',
            height: 60,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });
  });
}
