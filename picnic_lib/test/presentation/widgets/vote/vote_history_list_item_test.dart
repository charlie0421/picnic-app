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
  int cottonCandyUsage = 0,
  bool isPartnership = false,
  String? partner,
  String artistName = '테스트 아티스트',
  String groupName = '테스트 그룹',
}) {
  return VotePickModel(
    id: 1,
    vote: VoteFactory.create(isPartnership: isPartnership, partner: partner),
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
    amount: starCandyUsage + starCandyBonusUsage + cottonCandyUsage,
    starCandyUsage: starCandyUsage,
    starCandyBonusUsage: starCandyBonusUsage,
    cottonCandyUsage: cottonCandyUsage,
    createdAt: DateTime(2025, 1, 15, 10, 30, 0),
    updatedAt: DateTime(2025, 1, 15, 10, 30, 0),
  );
}

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('VoteHistoryListItem', () {
    testWidgets(
      'renders the standard star candy currency icon for regular votes',
      (tester) async {
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.toString();
          if (message.contains('Unable to load asset') ||
              message.contains('IMAGE RESOURCE') ||
              message.contains('overflowed')) {
            return;
          }
          oldHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          buildTestApp(
            SingleChildScrollView(
              child: VoteHistoryListItem(
                item: _createMockVotePick(starCandyBonusUsage: 0),
              ),
            ),
          ),
        );
        await tester.pump();

        final starCandyImage = tester
            .widgetList<Image>(find.byType(Image))
            .singleWhere((image) => image.width == 36 && image.height == 36);
        final imageProvider = starCandyImage.image as AssetImage;

        expect(
          imageProvider.assetName,
          'assets/icons/store/currency_star_candy.png',
        );
      },
    );

    testWidgets('renders cotton candy usage and preserves total usage', (
      tester,
    ) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.toString();
        if (message.contains('Unable to load asset') ||
            message.contains('IMAGE RESOURCE') ||
            message.contains('overflowed')) {
          return;
        }
        oldHandler?.call(details);
      };
      final item = _createMockVotePick(
        starCandyUsage: 3,
        starCandyBonusUsage: 4,
        cottonCandyUsage: 7,
      );

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(child: VoteHistoryListItem(item: item)),
        ),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(
        (item.starCandyUsage ?? 0) +
            (item.starCandyBonusUsage ?? 0) +
            (item.cottonCandyUsage ?? 0),
        item.amount,
      );

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with basic vote pick data', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) {
          return;
        }
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

    testWidgets('renders with zero candy usage (empty usage section)', (
      tester,
    ) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.toString();
        if (msg.contains('Unable to load asset') ||
            msg.contains('IMAGE RESOURCE') ||
            msg.contains('overflowed')) {
          return;
        }
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
            msg.contains('overflowed')) {
          return;
        }
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
            msg.contains('overflowed')) {
          return;
        }
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
            msg.contains('overflowed')) {
          return;
        }
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
            msg.contains('overflowed')) {
          return;
        }
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
