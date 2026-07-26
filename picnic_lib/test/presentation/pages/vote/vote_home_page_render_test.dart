import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
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
    setupMockSupabase({
      'vote': <dynamic>[],
      'pic_vote': <dynamic>[],
      'banner': <dynamic>[],
      'reward': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, widget) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('VoteHomePage render', () {
    testWidgets('renders empty state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteHomePage()),
      );

      expect(find.byType(VoteHomePage), findsOneWidget);
    });

    testWidgets('renders with vote data', (WidgetTester tester) async {
      final now = DateTime.now().toUtc();
      setupMockSupabase({
        'vote': [
          {
            'id': 1,
            'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
            'vote_category': 'birthday',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'vote_item': null,
            'created_at': now.toIso8601String(),
            'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
            'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
            'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
            'is_ended': false,
            'is_upcoming': false,
            'is_partnership': false,
            'partner': null,
            'reward': null,
          },
        ],
        'pic_vote': <dynamic>[],
        'banner': <dynamic>[],
        'reward': [
          {
            'id': 1,
            'title': {'ko': '포토카드'},
            'thumbnail': 'https://example.com/thumb.jpg',
            'overview_images': null,
            'location': null,
            'size_guide': null,
            'size_guide_images': null,
          },
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteHomePage()),
      );

      expect(find.byType(VoteHomePage), findsOneWidget);
    });

    testWidgets('renders logged out state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteHomePage(), loggedIn: false),
      );

      expect(find.byType(VoteHomePage), findsOneWidget);
    });
  });
}
