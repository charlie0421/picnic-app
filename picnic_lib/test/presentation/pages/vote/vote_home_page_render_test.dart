import 'package:flutter/material.dart';
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
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
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

    testWidgets('reward with null title renders instead of crashing', (
      WidgetTester tester,
    ) async {
      // `RewardModel.title` 은 순수 nullable DB 컬럼이다 — 운영자가 제목을
      // 비워두면 실제로 널이 온다. 리워드 리스트는 홈 ListView 의 첫 자식이라
      // 첫 프레임에 바로 그려지므로, `data[index].title!` 로 되돌리면 여기서
      // 널 단언이 터져 리워드 행이 RenderErrorBox 가 된다.
      setupMockSupabase({
        'vote': <dynamic>[],
        'pic_vote': <dynamic>[],
        'banner': <dynamic>[],
        'reward': [
          {
            'id': 1,
            'title': null,
            'thumbnail': null,
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
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: '제목이 널이면 빈 문자열로 접히고 리워드 행은 계속 그려져야 한다',
      );
    });
  });
}
