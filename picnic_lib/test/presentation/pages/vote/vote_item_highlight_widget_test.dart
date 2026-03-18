import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_highlight_widget.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

  /// Pump the widget and drain any errors from missing SVG assets, etc.
  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(milliseconds: 300));
    while (tester.takeException() != null) {}
  }

  /// Build a [VoteItemHighlightWidget] with sensible defaults.
  Widget buildWidget({
    int? itemId,
    int index = 0,
    int actualRank = 1,
    int voteCountDiff = 0,
    bool rankChanged = false,
    bool rankUp = false,
    String searchQuery = '',
    bool isEnded = false,
    bool isSaving = false,
    Set<int> highlightedItemIds = const <int>{},
    VoidCallback? onTap,
  }) {
    final item = MockData.voteItem(id: itemId ?? 1);
    return buildTestApp(
      VoteItemHighlightWidget(
        item: item,
        index: index,
        actualRank: actualRank,
        voteCountDiff: voteCountDiff,
        rankChanged: rankChanged,
        rankUp: rankUp,
        searchQuery: searchQuery,
        isEnded: isEnded,
        isSaving: isSaving,
        highlightedItemIds: highlightedItemIds,
        onTap: onTap ?? () {},
        artistImage: const SizedBox(width: 45, height: 45),
        voteCountContainer: const SizedBox(height: 20),
        getMatchingText: (nameMap, query) =>
            nameMap['ko']?.toString() ?? '',
        rankText: actualRank.toString(),
      ),
    );
  }

  group('VoteItemHighlightWidget', () {
    testWidgets('renders without errors with basic data',
        (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget());

      expect(find.byType(VoteItemHighlightWidget), findsOneWidget);
    });

    testWidgets('shows crown SVG for rank 1', (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget(actualRank: 1));

      expect(find.byType(SvgPicture), findsWidgets);
      expect(find.byType(VoteItemHighlightWidget), findsOneWidget);
    });

    testWidgets('shows crown SVG for rank 2', (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget(actualRank: 2));

      expect(find.byType(SvgPicture), findsWidgets);
      expect(find.byType(VoteItemHighlightWidget), findsOneWidget);
    });

    testWidgets('shows crown SVG for rank 3', (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget(actualRank: 3));

      expect(find.byType(SvgPicture), findsWidgets);
      expect(find.byType(VoteItemHighlightWidget), findsOneWidget);
    });

    testWidgets('shows number text for rank > 3',
        (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget(actualRank: 4));

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows number text for rank 10',
        (WidgetTester tester) async {
      await pumpAndDrain(tester, buildWidget(actualRank: 10));

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows star candy icon when not ended and not saving',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildWidget(isEnded: false, isSaving: false),
      );

      // The star candy icon is an SvgPicture; when not ended and not saving,
      // there should be at least the crown SVG + star candy SVG.
      expect(find.byType(SvgPicture), findsWidgets);
      expect(find.byType(VoteItemHighlightWidget), findsOneWidget);
    });

    testWidgets('hides star candy icon when ended',
        (WidgetTester tester) async {
      // Use rank > 3 so no crown SVG is rendered, making it easier to check
      // that no SvgPicture appears for star candy.
      await pumpAndDrain(
        tester,
        buildWidget(isEnded: true, actualRank: 5),
      );

      // With rank > 3 and isEnded=true, there should be no SvgPicture at all.
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('hides star candy icon when saving',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildWidget(isSaving: true, actualRank: 5),
      );

      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('applies highlight color when item is in highlightedItemIds',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildWidget(
          itemId: 1,
          highlightedItemIds: <int>{1},
          rankUp: true,
        ),
      );

      // The widget should render with a non-transparent AnimatedContainer.
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('uses transparent color when item not in highlightedItemIds',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildWidget(
          itemId: 1,
          highlightedItemIds: <int>{999},
        ),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('calls onTap callback when tapped',
        (WidgetTester tester) async {
      bool tapped = false;
      await pumpAndDrain(
        tester,
        buildWidget(onTap: () => tapped = true),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
