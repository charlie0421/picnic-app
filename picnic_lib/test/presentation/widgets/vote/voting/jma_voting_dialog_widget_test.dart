import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() async {
    // 프로덕션 폰트를 올린다 — 없으면 flutter_test 기본 폰트(글리프마다 1em)가
    // 텍스트를 과대 측정해서 다이얼로그가 없는 오버플로를 낸다.
    // 상세는 login_page_render_test.dart 의 setUpAll 주석 참고.
    await loadTestFonts();
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

  group('JmaVotingDialog widget tests', () {
    testWidgets('renders JmaVotingDialog widget', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('renders with VotePortal.pic portal type', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.pic,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(JmaVotingDialog), findsOneWidget);
    });

    testWidgets('displays artist name from voteItemModel', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      final artist = MockData.artist(
        nameKo: '지민',
        artistGroup: MockData.artistGroup(nameKo: 'BTS'),
      );
      final item = MockData.voteItem(artist: artist);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
            voteModel: voteModel,
            voteItemModel: item,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.text('지민'), findsOneWidget);
    });

    testWidgets('displays star candy amount', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 500, starCandyBonus: 20),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('shows default person icon when artist has no image',
        (tester) async {
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
          'name': <String, dynamic>{'ko': '아티스트'},
          'image': null,
        },
        'artist_group': null,
      });

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
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

    testWidgets('contains TextFormField for vote input', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
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
  });
}
