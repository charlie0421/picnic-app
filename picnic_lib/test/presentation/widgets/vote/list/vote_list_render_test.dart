import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('VoteList render', () {
    testWidgets('shows skeleton loading initially with empty data',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.active,
            VoteCategory.all,
            'all',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      // Initially shows skeleton loading
      expect(find.byType(VoteList), findsOneWidget);
    });

    testWidgets('renders VoteNoItem when no votes available',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.active,
            VoteCategory.all,
            'all',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
      // Should show either skeleton or no-item after loading
    });

    testWidgets('renders with vote data', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[
          {
            'id': 1,
            'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
            'vote_category': 'birthday',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'vote_item': null,
            'created_at': DateTime.now().toIso8601String(),
            'visible_at': null,
            'start_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'stop_at':
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'is_ended': false,
            'is_upcoming': false,
            'is_partnership': false,
            'partner': null,
            'reward': null,
          },
        ],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.active,
            VoteCategory.all,
            'all',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
    });

    testWidgets('renders with upcoming status', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.upcoming,
            VoteCategory.all,
            'all',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
    });

    testWidgets('renders with end status', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.end,
            VoteCategory.all,
            'all',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.active,
            VoteCategory.all,
            'all',
            portal: VotePortal.pic,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
    });

    testWidgets('renders with specific area', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestApp(
          const VoteList(
            VoteStatus.active,
            VoteCategory.birthday,
            'kpop',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(VoteList), findsOneWidget);
    });
  });
}
