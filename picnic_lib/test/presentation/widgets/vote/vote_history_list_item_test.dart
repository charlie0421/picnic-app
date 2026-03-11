import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_history_list_item.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/factories/vote_factory.dart';

VotePickModel _createMockVotePick({
  int starCandyUsage = 100,
  int starCandyBonusUsage = 50,
  bool isPartnership = false,
  String? partner,
  String artistName = '테스트 아티스트',
  String groupName = '테스트 그룹',
}) {
  return VotePickModel(
    id: 1,
    vote: VoteFactory.create(
      isPartnership: isPartnership,
      partner: partner,
    ),
    voteItem: VoteItemFactory.create(
      artist: ArtistModel(
        id: 1,
        name: {'ko': artistName},
        image: null,
        artistGroup: ArtistGroupModel(
          id: 1,
          name: {'ko': groupName},
          image: null,
        ),
      ),
    ),
    amount: 10,
    starCandyUsage: starCandyUsage,
    starCandyBonusUsage: starCandyBonusUsage,
    createdAt: DateTime(2025, 1, 15, 10, 30, 0),
    updatedAt: DateTime(2025, 1, 15, 10, 30, 0),
  );
}

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('VoteHistoryListItem', () {
    testWidgets('renders with basic vote pick data', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(item: _createMockVotePick()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteHistoryListItem), findsOneWidget);
      // Should display the date
      expect(find.textContaining('2025'), findsWidgets);
      // Should display artist name
      expect(find.text('테스트 아티스트'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with zero candy usage (empty usage section)',
        (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(
              item: _createMockVotePick(
                starCandyUsage: 0,
                starCandyBonusUsage: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteHistoryListItem), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with only star candy usage', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(
              item: _createMockVotePick(
                starCandyUsage: 500,
                starCandyBonusUsage: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('500'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with only bonus candy usage', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(
              item: _createMockVotePick(
                starCandyUsage: 0,
                starCandyBonusUsage: 200,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('200'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with both star and bonus candy', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(
              item: _createMockVotePick(
                starCandyUsage: 1000,
                starCandyBonusUsage: 300,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1,000'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders group name', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VoteHistoryListItem(
              item: _createMockVotePick(groupName: 'BTS'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BTS'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });
  });
}
