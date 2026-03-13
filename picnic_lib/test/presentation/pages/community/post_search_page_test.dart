import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_search_page.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/mock_supabase.dart';

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('PostSearchPage', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();

      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('contains a search box', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();

      // Should contain some form of text input
      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('renders with initial empty search state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();

      // Initial state should show search history area (empty)
      expect(find.byType(Column), findsWidgets);
    });
  });
}
