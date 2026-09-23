import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _PendingVotes extends AsyncVoteList {
  @override
  Future<List<VoteModel>> build(
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  }) => Completer<List<VoteModel>>().future;
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({'vote': []});
    // VoteList's loading skeleton overflows the headless test viewport
    // (pre-existing quirk, see vote_list_render_test.dart) — suppress like
    // the rest of the suite does instead of a plain pump().
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('VoteListContent rendering', () {
    testWidgets('status filter immediately shows its matching skeleton', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
          extraOverrides: [
            asyncVoteListProvider.overrideWith(_PendingVotes.new),
          ],
        ),
      );

      expect(
        tester.widget<VoteCardSkeleton>(find.byType(VoteCardSkeleton)).status,
        VoteCardStatus.ongoing,
      );
      for (final (status, expected) in [
        (VoteStatus.end, VoteCardStatus.ended),
        (VoteStatus.upcoming, VoteCardStatus.upcoming),
        (VoteStatus.active, VoteCardStatus.ongoing),
      ]) {
        await tester.tap(find.byType(DropdownButton<VoteStatus>));
        await pumpAndIgnoreErrors(tester);
        await tester.tap(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is DropdownMenuItem<VoteStatus> &&
                    widget.value == status,
              )
              .last,
        );
        await pumpAndIgnoreErrors(tester);
        expect(
          tester.widget<VoteCardSkeleton>(find.byType(VoteCardSkeleton)).status,
          expected,
        );
      }
    });

    testWidgets(
      'renders 5 vote-type chips with ALL first, regardless of isAdmin',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(const VoteListContent(isAdmin: false)),
        );
        await pumpAndIgnoreErrors(tester);

        // 탭 UI 대신 태그(칩): ALL + PICNIC/PIC CHART/MUSICAL/SPOTLIGHT = 5개.
        for (final label in [
          'ALL',
          'PICNIC',
          'PIC CHART',
          'MUSICAL',
          'SPOTLIGHT',
        ]) {
          expect(find.text(label), findsOneWidget, reason: 'chip $label');
        }
        // 더 이상 TabBar/TabBarView 를 쓰지 않는다.
        expect(find.byType(TabBar), findsNothing);
        expect(find.byType(TabBarView), findsNothing);
      },
    );

    testWidgets(
      'renders chips when isAdmin true (admin adds a status option, not a chip)',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(const VoteListContent(isAdmin: true)),
        );
        await pumpAndIgnoreErrors(tester);

        expect(find.text('ALL'), findsOneWidget);
        expect(find.text('SPOTLIGHT'), findsOneWidget);

        // Admin option is appended to the status dropdown's items instead.
        final dropdown = tester.widget<DropdownButton<VoteStatus>>(
          find.byType(DropdownButton<VoteStatus>),
        );
        expect(dropdown.items!.length, 4);
        expect(dropdown.items!.last.value, VoteStatus.debug);
      },
    );

    testWidgets('status dropdown has 3 options for non-admin', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const VoteListContent(isAdmin: false)),
      );
      await pumpAndIgnoreErrors(tester);

      final dropdown = tester.widget<DropdownButton<VoteStatus>>(
        find.byType(DropdownButton<VoteStatus>),
      );
      expect(dropdown.items!.length, 3);
      expect(dropdown.value, VoteStatus.active);
    });

    testWidgets('type chips can scroll horizontally', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const VoteListContent(isAdmin: false)),
      );
      await pumpAndIgnoreErrors(tester);

      final horizontalScrolls = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where((scroll) => scroll.scrollDirection == Axis.horizontal);
      expect(horizontalScrolls, isNotEmpty);
    });

    testWidgets('default selected chip is ALL (list area = all)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const VoteListContent(isAdmin: false)),
      );
      await pumpAndIgnoreErrors(tester);

      final voteList = tester.widget<VoteList>(find.byType(VoteList));
      expect((voteList.key as ValueKey).value, contains('all'));
    });

    testWidgets('tapping a chip swaps the list to that area', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const VoteListContent(isAdmin: false)),
      );
      await pumpAndIgnoreErrors(tester);

      await tester.tap(find.text('PICNIC'));
      await pumpAndIgnoreErrors(tester);

      final voteList = tester.widget<VoteList>(find.byType(VoteList));
      expect((voteList.key as ValueKey).value, contains('kpop'));
    });
  });

  group('VoteListContent ValueKey', () {
    testWidgets('different isAdmin values produce different keys', (
      tester,
    ) async {
      const widget1 = VoteListContent(
        key: ValueKey('vote_list_false'),
        isAdmin: false,
      );
      const widget2 = VoteListContent(
        key: ValueKey('vote_list_true'),
        isAdmin: true,
      );

      expect(widget1.key, isNot(widget2.key));
    });
  });

  group('VoteStatus/VoteCategory/VotePortal used in VoteListPage', () {
    test('VoteStatus has debug for admin option', () {
      expect(VoteStatus.debug, isNotNull);
      expect(VoteStatus.debug.name, 'debug');
    });

    test('VoteCategory.all is used as default', () {
      expect(VoteCategory.all, isNotNull);
      expect(VoteCategory.all.name, 'all');
    });

    test('VotePortal.vote is used for vote list', () {
      expect(VotePortal.vote, isNotNull);
      expect(VotePortal.vote.name, 'vote');
    });
  });
}
