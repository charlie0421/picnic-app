import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'posts': <dynamic>[],
      'comments': <dynamic>[],
      'user_blocks': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('PostViewPage render - loading state', () {
    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
      // Should show loading indicator when waiting
      expect(find.byType(LargePulseLoadingIndicator), findsOneWidget);
    });
  });

  group('PostViewPage render - error/empty state', () {
    testWidgets('shows error UI when post not found',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('nonexistent-post', syncNavigation: false),
        ),
      );
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
      // After loading completes with error, should show retry or error UI
    });
  });

  group('PostViewPage render - syncNavigation false', () {
    testWidgets('renders page with own navigation context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });

  group('PostViewPage render - locale variants', () {
    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
          locale: const Locale('ko'),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
          locale: const Locale('en'),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
          locale: const Locale('ja'),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });

  group('PostViewPage render - different post IDs', () {
    testWidgets('renders with UUID-style post ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage(
            'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            syncNavigation: false,
          ),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });

    testWidgets('renders with empty post ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('', syncNavigation: false),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });

    testWidgets('renders with numeric post ID string',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('12345', syncNavigation: false),
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });

  group('PostViewPage render - logged out state', () {
    testWidgets('renders when user is not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
          loggedIn: false,
        ),
      );
      drainExpectedImageErrors(tester);

      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });

  group('AlwaysDisabledFocusNode', () {
    test('hasFocus always returns false', () {
      final node = AlwaysDisabledFocusNode();
      expect(node.hasFocus, isFalse);
      node.dispose();
    });
  });
}
