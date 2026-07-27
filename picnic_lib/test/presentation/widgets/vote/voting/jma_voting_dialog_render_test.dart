import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

VoteModel _makeVote({int id = 1}) {
  final now = DateTime.now().toUtc();
  return VoteModel.fromJson({
    'id': id,
    'title': {'ko': 'JMA 투표', 'en': 'JMA Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': null,
    'visible_at': null,
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  });
}

VoteItemModel _makeVoteItem({int id = 1, int voteTotal = 5000}) {
  return VoteItemModel.fromJson({
    'id': id,
    'vote_id': 1,
    'vote_total': voteTotal,
    'artist': {
      'id': 10,
      'name': {'ko': '지민', 'en': 'Jimin'},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': null,
      },
    },
    'artist_group': null,
  });
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': <dynamic>[],
      'vote_item': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('JmaVotingDialog render', () {
    testWidgets('renders with default portal', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.pic,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with high vote total', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem(voteTotal: 999999);

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders logged out state', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
          loggedIn: false,
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('can find text input field', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
        ),
      );

      // The dialog should contain a TextField for vote count input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('renders with zero candy user', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(
            starCandy: 0,
            starCandyBonus: 0,
            jmaCandy: 0,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with high bonus candy user',
        (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(
            starCandy: 100,
            starCandyBonus: 500,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with zero vote total item',
        (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem(voteTotal: 0);

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('enter vote amount in text field',
        (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
        ),
      );

      // Find TextField and enter a vote amount
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '10');
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 300));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.vote,
          ),
          locale: const Locale('ja'),
          setting: MockData.setting(language: 'ja'),
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders pic portal with logged out state',
        (WidgetTester tester) async {
      final vote = _makeVote();
      final voteItem = _makeVoteItem();

      await pumpAndDrain(
        tester,
        buildTestApp(
          JmaVotingDialog(
            voteModel: vote,
            voteItemModel: voteItem,
            portalType: VotePortal.pic,
          ),
          loggedIn: false,
        ),
      );

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });
  });
}
