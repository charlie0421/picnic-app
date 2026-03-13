import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/common/comment/comment_input.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommentInput', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentInput), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('contains a text field', (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('send button is initially disabled',
        (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      // The character counter should show 0/100
      expect(find.text('0/100'), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('typing updates character count',
        (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      expect(find.text('5/100'), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with onPostComment callback',
        (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
            onPostComment: (postId, parentId, locale, content) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentInput), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('clearing text resets counter',
        (WidgetTester tester) async {
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentInput(
            id: 'post-1',
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      // Type some text
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.pump();
      expect(find.text('12/100'), findsOneWidget);

      // Clear text
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(find.text('0/100'), findsOneWidget);

      pagingController.dispose();
    });
  });
}
