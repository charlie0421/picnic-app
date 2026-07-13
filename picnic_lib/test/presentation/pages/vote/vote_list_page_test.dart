import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

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
    testWidgets('renders the 4 vote-type tabs regardless of isAdmin',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      // Vote-type tabs (area-based) are a fixed const config, not tied to admin.
      expect(find.byType(Tab), findsNWidgets(4));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets(
        'still renders 4 vote-type tabs when isAdmin true (admin adds a status option, not a tab)',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: true),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(Tab), findsNWidgets(4));

      // Admin option is appended to the status dropdown's items instead.
      final dropdown = tester.widget<DropdownButton<VoteStatus>>(
        find.byType(DropdownButton<VoteStatus>),
      );
      expect(dropdown.items!.length, 4);
      expect(dropdown.items!.last.value, VoteStatus.debug);
    });

    testWidgets('status dropdown has 3 options for non-admin', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      final dropdown = tester.widget<DropdownButton<VoteStatus>>(
        find.byType(DropdownButton<VoteStatus>),
      );
      expect(dropdown.items!.length, 3);
      expect(dropdown.value, VoteStatus.active);
    });

    testWidgets('tab bar is scrollable with tabAlignment.start', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
      expect(tabBar.tabAlignment, TabAlignment.start);
    });

    testWidgets('tab bar has indicator weight 3', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorWeight, 3);
    });

    testWidgets('TabBarView allows swipe (no NeverScrollableScrollPhysics)',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);

      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.physics, isNot(isA<NeverScrollableScrollPhysics>()));
    });
  });

  group('VoteListContent ValueKey', () {
    testWidgets('different isAdmin values produce different keys',
        (tester) async {
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
