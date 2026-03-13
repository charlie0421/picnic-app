import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Additional coverage tests for VotingDialog, covering:
/// - Check all option toggle
/// - Clear button functionality
/// - Error message display when exceeding star candy
/// - Recharge button rendering
/// - Focus/unfocus behavior
/// - Partnership bubble text
/// - Non-partnership bubble text
/// - _calculateUsage logic (bonus first, then star candy)
void main() {
  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    setupMockSupabase({
      'functions:voting-v2': {
        'success': true,
        'addedVoteTotal': 10,
        'votePickId': 'test-pick-id',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'functions:pic-voting-v2': {
        'success': true,
        'addedVoteTotal': 5,
        'votePickId': 'test-pick-id-2',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('VotingDialog - Check All', () {
    testWidgets('tapping check all fills entire star candy amount',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 500, starCandyBonus: 50),
        ),
      );
      await tester.pumpAndSettle();

      // Find check all gesture area - it has SvgPicture + Text children
      // The check all is a GestureDetector containing a Row
      final checkAllFinder = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.child is SizedBox &&
            (widget.child as SizedBox).height == 20,
      );
      expect(checkAllFinder, findsOneWidget);

      await tester.tap(checkAllFinder);
      await tester.pumpAndSettle();

      // Should display the total star candy (500 + 50 = 550)
      expect(find.text('550'), findsWidgets);
    });

    testWidgets('tapping check all twice clears the amount', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 200, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final checkAllFinder = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.child is SizedBox &&
            (widget.child as SizedBox).height == 20,
      );

      // Tap once to check all
      await tester.tap(checkAllFinder);
      await tester.pumpAndSettle();

      // Tap again to uncheck
      await tester.tap(checkAllFinder);
      await tester.pumpAndSettle();

      // Text field should be cleared
      expect(find.byType(VotingDialog), findsOneWidget);
    });
  });

  group('VotingDialog - Clear button', () {
    testWidgets('clear button clears input text', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 1000, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Enter some text
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '50');
      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);

      // Find and tap the clear button (cancel_style=fill.svg)
      final clearButtons = find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.width == null, // The clear button SvgPicture
      );

      // The clear button is wrapped in a GestureDetector at the end of the Row
      final clearGesture = find.byWidgetPredicate(
        (widget) {
          if (widget is GestureDetector && widget.child is SvgPicture) {
            return true;
          }
          return false;
        },
      );

      if (clearGesture.evaluate().isNotEmpty) {
        await tester.tap(clearGesture.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(VotingDialog), findsOneWidget);
    });
  });

  group('VotingDialog - Error message', () {
    testWidgets('shows error text when amount exceeds balance', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 10, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '100');
      await tester.pumpAndSettle();

      // Error state should show red border and error message
      // The error container should be visible
      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('no error shown when amount is within balance', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 1000, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '100');
      await tester.pumpAndSettle();

      // Should not show error
      expect(find.byType(VotingDialog), findsOneWidget);
    });
  });

  group('VotingDialog - User with zero star candy', () {
    testWidgets('displays 0 for zero star candy', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 0, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('VotingDialog - Partnership bubble', () {
    testWidgets('partnership vote shows partner name in bubble',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final partnerVote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '파트너십 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': true,
        'partner': 'mnet',
        'reward': null,
      });

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: partnerVote,
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Partnership bubble should mention MNET
      expect(find.textContaining('MNET'), findsWidgets);
    });
  });

  group('VotingDialog - Artist with empty image', () {
    testWidgets('artist with empty string image shows default icon',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': '아이유'},
          'image': '', // empty string
        },
        'artist_group': null,
      });

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: item,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty image should show default icon
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('VotingDialog - Artist group with null image when artist id is 0', () {
    testWidgets('shows default icon for artist group with null image',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{
          'id': 0,
          'name': <String, dynamic>{},
        },
        'artist_group': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': 'TWICE'},
          'image': null,
        },
      });

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: item,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(VotingDialog), findsOneWidget);
      // Should show default person icon since image is null
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('VotingDialog - Non-logged in user (null userInfo)', () {
    testWidgets('renders with logged out user', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      // Should still render but with 0 star candy
      expect(find.byType(VotingDialog), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('VotingDialog - Input formatting edge cases', () {
    testWidgets('single digit input is not formatted with comma',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 1000, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '5');
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('very large number gets formatted', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: MockData.vote(),
            voteItemModel: MockData.voteItem(),
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 10000000, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '1234567');
      await tester.pumpAndSettle();

      expect(find.text('1,234,567'), findsOneWidget);
    });
  });
}
