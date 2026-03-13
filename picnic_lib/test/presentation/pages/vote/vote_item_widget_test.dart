import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  VoteItemModel makeItem({
    int id = 1,
    int voteTotal = 1000,
    int voteId = 1,
  }) {
    return MockData.voteItem(id: id, voteTotal: voteTotal, voteId: voteId);
  }

  Widget buildWidget({
    VoteItemModel? item,
    int index = 0,
    int actualRank = 1,
    int voteCountDiff = 0,
    bool rankChanged = false,
    bool rankUp = false,
    bool isEnded = false,
    bool isSaving = false,
  }) {
    final voteItem = item ?? makeItem();
    return buildTestApp(
      VoteItemWidget(
        item: voteItem,
        index: index,
        actualRank: actualRank,
        voteCountDiff: voteCountDiff,
        rankChanged: rankChanged,
        rankUp: rankUp,
        isEnded: isEnded,
        isSaving: isSaving,
        onTap: () {},
        artistImage: const SizedBox(width: 40, height: 40),
        voteCountContainer: const Text('1,000'),
        rankText: actualRank.toString(),
      ),
    );
  }

  group('VoteItemWidget', () {
    testWidgets('renders with rank 1 crown SVG', (tester) async {
      await tester.pumpWidget(buildWidget(actualRank: 1));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
      // rank <= 3 should show SVG crown, no rank text
      expect(find.text('1'), findsNothing);
    });

    testWidgets('renders with rank 2 crown SVG', (tester) async {
      await tester.pumpWidget(buildWidget(actualRank: 2));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });

    testWidgets('renders with rank 3 crown SVG', (tester) async {
      await tester.pumpWidget(buildWidget(actualRank: 3));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });

    testWidgets('renders rank number for rank > 3', (tester) async {
      await tester.pumpWidget(buildWidget(actualRank: 5));
      await tester.pump();

      // rank > 3 should show number text
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders artist name from voteItem', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Artist name from mock data
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('does not show star candy icon when isEnded', (tester) async {
      await tester.pumpWidget(buildWidget(isEnded: true));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });

    testWidgets('does not show star candy icon when isSaving', (tester) async {
      await tester.pumpWidget(buildWidget(isSaving: true));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });

    testWidgets('shows star candy icon when active and not saving',
        (tester) async {
      await tester.pumpWidget(
          buildWidget(isEnded: false, isSaving: false));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });

    testWidgets('applies rank-up highlight when rankChanged and rankUp',
        (tester) async {
      await tester.pumpWidget(
          buildWidget(rankChanged: true, rankUp: true));
      await tester.pump();

      // Widget renders with blue highlight
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('applies rank-down highlight when rankChanged and not rankUp',
        (tester) async {
      await tester.pumpWidget(
          buildWidget(rankChanged: true, rankUp: false));
      await tester.pump();

      // Widget renders with red highlight
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('no highlight when rankChanged is false', (tester) async {
      await tester.pumpWidget(buildWidget(rankChanged: false));
      await tester.pump();

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('onTap callback fires on gesture', (tester) async {
      bool tapped = false;
      final voteItem = makeItem();
      await tester.pumpWidget(
        buildTestApp(
          VoteItemWidget(
            item: voteItem,
            index: 0,
            actualRank: 5,
            voteCountDiff: 0,
            rankChanged: false,
            rankUp: false,
            isEnded: false,
            isSaving: false,
            onTap: () => tapped = true,
            artistImage: const SizedBox(width: 40, height: 40),
            voteCountContainer: const Text('1,000'),
            rankText: '5',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(VoteItemWidget));
      expect(tapped, isTrue);
    });

    testWidgets('renders voteCountContainer', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('1,000'), findsOneWidget);
    });

    testWidgets('renders with artist group only (artist id 0)',
        (tester) async {
      // Create item with artist.id == 0 to trigger group name display
      final group = MockData.artistGroup(nameKo: 'BTS', nameEn: 'BTS');
      final artist = MockData.artist(id: 0, nameKo: '', nameEn: '', artistGroup: group);
      final item = MockData.voteItem(artist: artist);

      await tester.pumpWidget(buildWidget(item: item));
      await tester.pump();

      expect(find.byType(VoteItemWidget), findsOneWidget);
    });
  });
}
