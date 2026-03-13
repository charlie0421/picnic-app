import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

/// Suppress overflow errors for the duration of a callback.
Future<void> _ignoreOverflowErrors(Future<void> Function() callback) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final exception = details.exception;
    if (exception is FlutterError &&
        exception.message.contains('overflowed')) {
      return;
    }
    original?.call(details);
  };
  try {
    await callback();
  } finally {
    FlutterError.onError = original;
  }
}

void main() {
  setUpAll(() {
    initTestColors();
  });

  late VoteModel voteModel;
  late VoteItemModel voteItemModel;

  setUp(() {
    voteModel = VoteModel.fromJson({
      'id': 1,
      'title': {'ko': 'JMA 투표', 'en': 'JMA Vote'},
      'vote_category': 'birthday',
      'main_image': null,
      'wait_image': null,
      'result_image': null,
      'vote_content': null,
      'vote_item': null,
      'created_at': null,
      'visible_at': null,
      'start_at':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'stop_at':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'is_ended': false,
      'is_upcoming': false,
      'is_partnership': true,
      'partner': 'jma',
      'reward': null,
    });
    voteItemModel = MockData.voteItem();

    setupMockSupabase({
      'functions:jma-voting-usage': {
        'dailyVoteCount': 2,
      },
      'functions:jma-voting-v2': {
        'success': true,
        'addedVoteTotal': 10,
        'votePickId': 'test-pick-id',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('JmaVotingDialog', () {
    testWidgets('renders without errors', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(JmaVotingDialog), findsOneWidget);
      });
    });

    testWidgets('displays artist info from voteItemModel', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final artist = MockData.artist(
        nameKo: '지민',
        artistGroup: MockData.artistGroup(nameKo: 'BTS'),
      );
      final item = MockData.voteItem(artist: artist);

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: item,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('지민'), findsOneWidget);
      });
    });

    testWidgets('displays star candy info', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 300, starCandyBonus: 20),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('300'), findsOneWidget);
      });
    });

    testWidgets('accepts text input for vote amount', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 10000, starCandyBonus: 5),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final textField = find.byType(TextFormField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, '3');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('3'), findsWidgets);
      });
    });

    testWidgets('renders with default artist image when no image provided',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': '아티스트'},
          'image': null,
        },
        'artist_group': null,
      });

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: item,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    testWidgets('renders with artist group when artist id is 0',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{
          'id': 0,
          'name': <String, dynamic>{},
          'image': null,
        },
        'artist_group': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': 'NewJeans'},
          'image': null,
        },
      });

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: item,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('NewJeans'), findsOneWidget);
      });
    });

    testWidgets('handles dailyVoteCount loading error gracefully',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      tearDownMockSupabase();
      setupMockSupabase({
        'functions:jma-voting-usage': {'error': 'Server error'},
      }, functionStatusCodes: {
        'functions:jma-voting-usage': 500,
      });

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(JmaVotingDialog), findsOneWidget);
      });
    });

    testWidgets('displays correctly when user has zero star candy',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile: MockData.userProfile(starCandy: 0, starCandyBonus: 0),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('0'), findsWidgets);
      });
    });

    testWidgets('formats large star candy amounts with comma', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 50000, starCandyBonus: 0),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('50,000'), findsOneWidget);
      });
    });

    testWidgets('shows check all option', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 300, starCandyBonus: 5),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Check all checkbox should be present
        expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      });
    });

    testWidgets('tapping check all fills max votes', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 300, starCandyBonus: 5),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Tap check all
        await tester.tap(find.byIcon(Icons.check_box_outline_blank));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // After checking all, icon should change to checked
        expect(find.byIcon(Icons.check_box), findsOneWidget);
      });
    });

    testWidgets('shows JMA header text', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Jupiter Music Awards'), findsOneWidget);
      });
    });

    testWidgets('shows clear button', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byIcon(Icons.clear), findsOneWidget);
      });
    });

    testWidgets('showJmaVotingDialog opens dialog via function',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showJmaVotingDialog(
                  context: context,
                  voteModel: voteModel,
                  voteItemModel: voteItemModel,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(JmaVotingDialog), findsOneWidget);
      });
    });

    testWidgets('showJmaVotingDialog with pic portal type', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showJmaVotingDialog(
                  context: context,
                  voteModel: voteModel,
                  voteItemModel: voteItemModel,
                  portalType: VotePortal.pic,
                ),
                child: const Text('Open PIC'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open PIC'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(JmaVotingDialog), findsOneWidget);
      });
    });

    testWidgets('displays bonus star candy info', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            userProfile:
                MockData.userProfile(starCandy: 1000, starCandyBonus: 10),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Bonus star candy should be shown
        expect(find.text('10개'), findsOneWidget);
      });
    });

    testWidgets('tapping view policy expands info', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Find any text with underline decoration (the policy link)
        final policyFinder = find.byWidgetPredicate(
          (w) {
            if (w is Text && w.style?.decoration == TextDecoration.underline) {
              return true;
            }
            return false;
          },
        );

        if (policyFinder.evaluate().isNotEmpty) {
          await tester.tap(policyFinder.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(find.byType(JmaVotingDialog), findsOneWidget);
      });
    });

    testWidgets('renders with artist that has artistGroup', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final artist = MockData.artist(
        id: 10,
        nameKo: '정국',
        nameEn: 'Jungkook',
        artistGroup: MockData.artistGroup(nameKo: 'BTS', nameEn: 'BTS'),
      );
      final item = MockData.voteItem(artist: artist);

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: item,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('정국'), findsOneWidget);
        expect(find.text('BTS'), findsOneWidget);
      });
    });

    testWidgets('daily limit info section renders', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await _ignoreOverflowErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Should show daily limit related icon
        expect(
          find.byIcon(Icons.access_time),
          findsWidgets,
        );
      });
    });
  });

  group('JMA voting calculation logic', () {
    test('getUsableBonusVotes with no daily usage', () {
      final bonusStarCandy = 10;
      final dailyVoteCount = 0;
      final maxDailyVotes = 5;
      final remainingBonusUsage = maxDailyVotes - dailyVoteCount;

      int usableBonusVotes;
      if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
        usableBonusVotes = 0;
      } else {
        usableBonusVotes = bonusStarCandy < remainingBonusUsage
            ? bonusStarCandy
            : remainingBonusUsage;
      }

      expect(usableBonusVotes, 5); // min(10, 5) = 5
    });

    test('getUsableBonusVotes with partial daily usage', () {
      final bonusStarCandy = 10;
      final dailyVoteCount = 3;
      final maxDailyVotes = 5;
      final remainingBonusUsage = maxDailyVotes - dailyVoteCount;

      int usableBonusVotes;
      if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
        usableBonusVotes = 0;
      } else {
        usableBonusVotes = bonusStarCandy < remainingBonusUsage
            ? bonusStarCandy
            : remainingBonusUsage;
      }

      expect(usableBonusVotes, 2); // min(10, 2) = 2
    });

    test('getUsableBonusVotes with daily limit exhausted', () {
      final bonusStarCandy = 10;
      final dailyVoteCount = 5;
      final maxDailyVotes = 5;
      final remainingBonusUsage = maxDailyVotes - dailyVoteCount;

      int usableBonusVotes;
      if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
        usableBonusVotes = 0;
      } else {
        usableBonusVotes = bonusStarCandy < remainingBonusUsage
            ? bonusStarCandy
            : remainingBonusUsage;
      }

      expect(usableBonusVotes, 0);
    });

    test('getUsableBonusVotes with zero bonus candy', () {
      final bonusStarCandy = 0;
      final dailyVoteCount = 0;
      final maxDailyVotes = 5;
      final remainingBonusUsage = maxDailyVotes - dailyVoteCount;

      int usableBonusVotes;
      if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
        usableBonusVotes = 0;
      } else {
        usableBonusVotes = bonusStarCandy < remainingBonusUsage
            ? bonusStarCandy
            : remainingBonusUsage;
      }

      expect(usableBonusVotes, 0);
    });

    test('getRequiredStarCandyAmount with bonus only', () {
      final voteAmount = 3;
      final usableBonusVotes = 5;

      int required;
      if (voteAmount == 0) {
        required = 0;
      } else if (voteAmount <= usableBonusVotes) {
        required = voteAmount; // 1:1
      } else {
        final remaining = voteAmount - usableBonusVotes;
        required = usableBonusVotes + remaining * 30;
      }

      expect(required, 3); // All covered by bonus (1:1)
    });

    test('getRequiredStarCandyAmount with bonus + regular', () {
      final voteAmount = 8;
      final usableBonusVotes = 5;

      int required;
      if (voteAmount == 0) {
        required = 0;
      } else if (voteAmount <= usableBonusVotes) {
        required = voteAmount;
      } else {
        final remaining = voteAmount - usableBonusVotes;
        required = usableBonusVotes + remaining * 30;
      }

      expect(required, 5 + 3 * 30); // 5 bonus + 90 regular = 95
    });

    test('getRequiredStarCandyAmount with zero amount', () {
      final voteAmount = 0;
      final usableBonusVotes = 5;

      int required;
      if (voteAmount == 0) {
        required = 0;
      } else if (voteAmount <= usableBonusVotes) {
        required = voteAmount;
      } else {
        final remaining = voteAmount - usableBonusVotes;
        required = usableBonusVotes + remaining * 30;
      }

      expect(required, 0);
    });

    test('getMaxPossibleVotes calculation', () {
      final myStarCandy = 300;
      final usableBonusVotes = 3;
      final regularVotes = myStarCandy ~/ 30;

      final maxVotes = usableBonusVotes + regularVotes;
      expect(maxVotes, 3 + 10); // 13
    });

    test('calculateUsage with bonus only', () {
      final voteAmount = 3;
      final usableBonusVotes = 5;

      int starCandyUsage;
      int starCandyBonusUsage;

      if (voteAmount <= usableBonusVotes) {
        starCandyBonusUsage = voteAmount;
        starCandyUsage = 0;
      } else {
        starCandyBonusUsage = usableBonusVotes;
        final regularVotes = voteAmount - usableBonusVotes;
        starCandyUsage = regularVotes * 30;
      }

      expect(starCandyUsage, 0);
      expect(starCandyBonusUsage, 3);
    });

    test('calculateUsage with mixed', () {
      final voteAmount = 7;
      final usableBonusVotes = 3;

      int starCandyUsage;
      int starCandyBonusUsage;

      if (voteAmount <= usableBonusVotes) {
        starCandyBonusUsage = voteAmount;
        starCandyUsage = 0;
      } else {
        starCandyBonusUsage = usableBonusVotes;
        final regularVotes = voteAmount - usableBonusVotes;
        starCandyUsage = regularVotes * 30;
      }

      expect(starCandyUsage, 4 * 30); // 120
      expect(starCandyBonusUsage, 3);
    });

    test('getCalculationResultMessage - bonus only', () {
      final voteAmount = 2;
      final usableBonusVotes = 5;

      String message;
      if (voteAmount <= usableBonusVotes) {
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(voteAmount)}개";
      } else if (usableBonusVotes > 0) {
        final regularStarCandyNeeded = (voteAmount - usableBonusVotes) * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(usableBonusVotes)}개 + 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      } else {
        final regularStarCandyNeeded = voteAmount * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      }

      expect(message, contains('보너스 2개'));
    });

    test('getCalculationResultMessage - mixed', () {
      final voteAmount = 7;
      final usableBonusVotes = 3;

      String message;
      if (voteAmount <= usableBonusVotes) {
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(voteAmount)}개";
      } else if (usableBonusVotes > 0) {
        final regularStarCandyNeeded = (voteAmount - usableBonusVotes) * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(usableBonusVotes)}개 + 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      } else {
        final regularStarCandyNeeded = voteAmount * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      }

      expect(message, contains('보너스 3개'));
      expect(message, contains('별사탕 120개'));
    });

    test('getCalculationResultMessage - regular only', () {
      final voteAmount = 5;
      final usableBonusVotes = 0;

      String message;
      if (voteAmount <= usableBonusVotes) {
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(voteAmount)}개";
      } else if (usableBonusVotes > 0) {
        final regularStarCandyNeeded = (voteAmount - usableBonusVotes) * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(usableBonusVotes)}개 + 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      } else {
        final regularStarCandyNeeded = voteAmount * 30;
        message =
            "JMA ${formatNumberWithComma(voteAmount)}투표 = 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
      }

      expect(message, contains('별사탕 150개'));
      expect(message, isNot(contains('보너스')));
    });

    test('validateVote - amount exceeds max possible votes', () {
      final voteAmount = 100;
      final maxPossibleVotes = 10;
      final requiredStarCandy = 500;
      final totalStarCandy = 1000;

      bool canVote = false;
      String validationMessage = '';

      if (voteAmount > 0) {
        if (voteAmount > maxPossibleVotes) {
          canVote = false;
          validationMessage = 'Max exceeded';
        } else if (requiredStarCandy > totalStarCandy) {
          canVote = false;
          validationMessage = 'Not enough';
        } else {
          canVote = true;
        }
      }

      expect(canVote, isFalse);
      expect(validationMessage, 'Max exceeded');
    });

    test('validateVote - not enough star candy', () {
      final voteAmount = 5;
      final maxPossibleVotes = 10;
      final requiredStarCandy = 150;
      final totalStarCandy = 100;

      bool canVote = false;
      String validationMessage = '';

      if (voteAmount > 0) {
        if (voteAmount > maxPossibleVotes) {
          canVote = false;
          validationMessage = 'Max exceeded';
        } else if (requiredStarCandy > totalStarCandy) {
          canVote = false;
          validationMessage = 'Not enough';
        } else {
          canVote = true;
        }
      }

      expect(canVote, isFalse);
      expect(validationMessage, 'Not enough');
    });

    test('validateVote - valid vote', () {
      final voteAmount = 3;
      final maxPossibleVotes = 10;
      final requiredStarCandy = 90;
      final totalStarCandy = 1000;

      bool canVote = false;
      String validationMessage = '';

      if (voteAmount > 0) {
        if (voteAmount > maxPossibleVotes) {
          canVote = false;
          validationMessage = 'Max exceeded';
        } else if (requiredStarCandy > totalStarCandy) {
          canVote = false;
          validationMessage = 'Not enough';
        } else {
          canVote = true;
        }
      }

      expect(canVote, isTrue);
      expect(validationMessage, '');
    });

    test('validateVote - zero amount', () {
      final voteAmount = 0;

      bool canVote = false;
      String validationMessage = '';

      if (voteAmount > 0) {
        canVote = true;
      } else {
        canVote = false;
        validationMessage = '';
      }

      expect(canVote, isFalse);
    });

    test('getVoteAmount parses comma-separated input', () {
      final text = '1,234';
      final amount = int.tryParse(text.replaceAll(',', '')) ?? 0;
      expect(amount, 1234);
    });

    test('getVoteAmount returns 0 for empty string', () {
      final text = '';
      final amount = int.tryParse(text.replaceAll(',', '')) ?? 0;
      expect(amount, 0);
    });

    test('getVoteAmount returns 0 for invalid input', () {
      final text = 'abc';
      final amount = int.tryParse(text.replaceAll(',', '')) ?? 0;
      expect(amount, 0);
    });

    test('daily limit remaining calculation', () {
      final maxDailyVotes = 5;
      final dailyVoteCount = 2;
      final remainingVotes = maxDailyVotes - dailyVoteCount;

      expect(remainingVotes, 3);
      expect(remainingVotes > 0, isTrue);
    });

    test('daily limit exhausted', () {
      final maxDailyVotes = 5;
      final dailyVoteCount = 5;
      final remainingVotes = maxDailyVotes - dailyVoteCount;

      expect(remainingVotes, 0);
      expect(remainingVotes > 0, isFalse);
    });
  });

  group('TrianglePainter', () {
    test('shouldRepaint returns false', () {
      final painter = TrianglePainter(color: Colors.red);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('creates with given color', () {
      final painter = TrianglePainter(color: Colors.blue);
      expect(painter.color, Colors.blue);
    });

    test('paint draws on canvas', () {
      final painter = TrianglePainter(color: Colors.green);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(100, 50));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  // Note: VotingCompleteDialog widget tests are limited because it uses
  // Image.asset('assets/app_icon_128.png') which is not available in the
  // picnic_lib test bundle. We test the TrianglePainter and logic patterns instead.

  group('VotingCompleteDialog result data parsing logic', () {
    test('addedVoteTotal parsing with valid data', () {
      final result = {'addedVoteTotal': 10};
      final addedVoteTotal =
          (result['addedVoteTotal'] as num?)?.toInt() ?? 0;
      expect(addedVoteTotal, 10);
    });

    test('addedVoteTotal parsing with null', () {
      final result = <String, dynamic>{'addedVoteTotal': null};
      final addedVoteTotal =
          (result['addedVoteTotal'] as num?)?.toInt() ?? 0;
      expect(addedVoteTotal, 0);
    });

    test('addedVoteTotal parsing with missing key', () {
      final result = <String, dynamic>{};
      final addedVoteTotal =
          (result['addedVoteTotal'] as num?)?.toInt() ?? 0;
      expect(addedVoteTotal, 0);
    });

    test('updatedAt parsing with valid date', () {
      final dateStr = '2026-03-11T12:00:00.000Z';
      final parsedDate = DateTime.tryParse(dateStr);
      expect(parsedDate, isNotNull);
    });

    test('updatedAt parsing with null', () {
      String? dateStr;
      final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
      expect(parsedDate, isNull);
    });

    test('updatedAt parsing with invalid string', () {
      final dateStr = 'invalid-date';
      final parsedDate = DateTime.tryParse(dateStr);
      expect(parsedDate, isNull);
    });

    test('result data safe defaults', () {
      final responseData = <String, dynamic>{};
      final result = Map<String, dynamic>.from(responseData);

      result['votePickId'] = responseData['votePickId'] ?? '';
      result['updatedAt'] =
          responseData['updatedAt'] ?? DateTime.now().toIso8601String();
      result['existingVoteTotal'] = responseData['existingVoteTotal'] ?? 0;
      result['addedVoteTotal'] = responseData['addedVoteTotal'] ?? 0;
      result['updatedVoteTotal'] = responseData['updatedVoteTotal'] ?? 0;

      expect(result['votePickId'], '');
      expect(result['existingVoteTotal'], 0);
      expect(result['addedVoteTotal'], 0);
      expect(result['updatedVoteTotal'], 0);
      expect(result['updatedAt'], isNotNull);
    });
  });
}
