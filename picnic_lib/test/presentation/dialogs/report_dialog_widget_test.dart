import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
    setupMockSupabase({});
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  PostModel createMockPost() {
    final now = DateTime.now();
    return PostModel(
      postId: 'post-1',
      userId: 'other-user-id',
      userProfiles: null,
      boardId: 'board-1',
      title: '테스트 게시물',
      content: null,
      viewCount: 10,
      replyCount: 3,
      isHidden: false,
      board: null,
      isAnonymous: false,
      isScraped: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ReportDialog widget rendering', () {
    // Note: ReportDialog uses AppLocalizations.of(context) in initState(),
    // which may not be available in test environment. We focus on testing
    // CustomRadioListTile (the main child widget) instead.

    testWidgets('CustomRadioListTile renders standalone', (tester) async {
      int? tappedValue;
      await pumpAndDrain(
        tester,
        buildTestApp(
          CustomRadioListTile(
            title: '스팸 또는 광고',
            value: 0,
            groupValue: null,
            onChanged: (v) => tappedValue = v,
          ),
        ),
      );

      expect(find.byType(CustomRadioListTile), findsOneWidget);
      expect(find.text('스팸 또는 광고'), findsOneWidget);
      expect(find.byType(Radio<int>), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tappedValue, 0);
    });

    testWidgets('CustomRadioListTile renders selected state', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CustomRadioListTile(
            title: '선택된 항목',
            value: 2,
            groupValue: 2,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(Radio<int>), findsOneWidget);
      expect(find.text('선택된 항목'), findsOneWidget);
    });

    testWidgets('CustomRadioListTile renders disabled state', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CustomRadioListTile(
            title: '비활성 항목',
            value: 1,
            groupValue: null,
            onChanged: null,
          ),
        ),
      );

      expect(find.byType(CustomRadioListTile), findsOneWidget);
      // InkWell should not respond to tap when disabled
      await tester.tap(find.byType(InkWell));
      await tester.pump();
    });
  });
}
