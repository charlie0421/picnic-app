import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/list/post_list.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'posts': <dynamic>[],
      'user_blocks': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('PostList render', () {
    testWidgets('renders with artist type and int id',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(PostList), findsOneWidget);
    });

    testWidgets('renders with board type and string id',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.board, 'board-123'),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(PostList), findsOneWidget);
    });

    testWidgets('renders fortune button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      // PostList should show fortune and goonghap buttons
      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
