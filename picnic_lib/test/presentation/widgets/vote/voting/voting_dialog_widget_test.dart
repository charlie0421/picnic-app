import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  late VoteModel voteModel;
  late VoteItemModel voteItemModel;

  setUp(() {
    voteModel = MockData.vote();
    voteItemModel = MockData.voteItem();

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

  group('VotingDialog widget tests', () {
    testWidgets('renders VotingDialog with VotePortal.vote', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('renders VotingDialog with VotePortal.pic', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.pic,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('displays star candy total from user profile', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 500, starCandyBonus: 50),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      // Star candy total = 500 + 50 = 550
      expect(find.text('550'), findsOneWidget);
    });

    testWidgets('displays artist name and group', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      final artist = MockData.artist(
        nameKo: '정국',
        artistGroup: MockData.artistGroup(nameKo: 'BTS'),
      );
      final item = MockData.voteItem(artist: artist);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: item,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.text('정국'), findsOneWidget);
      expect(find.text('BTS'), findsOneWidget);
    });

    testWidgets('shows default icon when artist has no image', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': '테스트'},
          'image': null,
        },
        'artist_group': null,
      });

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: item,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('contains TextFormField for vote amount input',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('entering text updates vote amount field', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 1000, starCandyBonus: 0),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '50');
      await pumpAndIgnoreErrors(tester);

      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('formats large numbers with comma in display', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile:
              MockData.userProfile(starCandy: 100000, starCandyBonus: 0),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.text('100,000'), findsOneWidget);
    });
  });
}
