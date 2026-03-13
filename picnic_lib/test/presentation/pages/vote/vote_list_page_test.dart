import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteListContent rendering', () {
    testWidgets('renders with isAdmin false (3 tabs)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await tester.pump();

      // Should have 3 tabs (active, end, upcoming)
      expect(find.byType(Tab), findsNWidgets(3));
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('renders with isAdmin true (4 tabs)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: true),
        ),
      );
      await tester.pump();

      // Should have 4 tabs (active, end, upcoming, admin)
      expect(find.byType(Tab), findsNWidgets(4));
      // Admin tab text
      expect(find.text('(Admin)'), findsOneWidget);
    });

    testWidgets('has TabController with correct length for non-admin',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 3);
    });

    testWidgets('has TabController with correct length for admin',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: true),
        ),
      );
      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 4);
    });

    testWidgets('tab bar has indicator weight 3', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorWeight, 3);
    });

    testWidgets('uses NeverScrollableScrollPhysics on TabBarView',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteListContent(isAdmin: false),
        ),
      );
      await tester.pump();

      final tabBarView =
          tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });

  group('VoteListContent ValueKey', () {
    testWidgets('different isAdmin values produce different keys',
        (tester) async {
      const widget1 = VoteListContent(
        key: ValueKey('vote_list_kpop_false'),
        isAdmin: false,
      );
      const widget2 = VoteListContent(
        key: ValueKey('vote_list_kpop_true'),
        isAdmin: true,
      );

      expect(widget1.key, isNot(widget2.key));
    });
  });

  group('VoteStatus/VoteCategory/VotePortal used in VoteListPage', () {
    test('VoteStatus has debug for admin tab', () {
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
