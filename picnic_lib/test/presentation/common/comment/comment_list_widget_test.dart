import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/bottom_sheet_header.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
    setupMockSupabase({
      'post_comment': <Map<String, dynamic>>[],
    });
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('CommentList widget rendering', () {
    testWidgets('renders with title and basic structure', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          CommentList(
            title: '댓글',
            id: 'post-1',
          ),
          extraOverrides: [
            parentItemProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(CommentList), findsOneWidget);
      expect(find.byType(BottomSheetHeader), findsOneWidget);
      expect(find.text('댓글'), findsOneWidget);
    });

    testWidgets('renders Scaffold inside', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          CommentList(
            title: '코멘트',
            id: 'post-2',
          ),
          extraOverrides: [
            parentItemProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders GestureDetector and RefreshIndicator', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          CommentList(
            title: '테스트 댓글',
            id: 'post-3',
          ),
          extraOverrides: [
            parentItemProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('renders with optional callbacks', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          CommentList(
            title: '댓글',
            id: 'post-5',
            openCommentsModal: () {},
            openReportModal: () {},
          ),
          extraOverrides: [
            parentItemProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(CommentList), findsOneWidget);
    });

    testWidgets('renders container with decoration', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          CommentList(
            title: '댓글',
            id: 'post-6',
          ),
          extraOverrides: [
            parentItemProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });
}
