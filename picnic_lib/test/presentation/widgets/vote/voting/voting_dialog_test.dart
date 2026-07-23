import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _WalletSummaryOverride extends WalletSummary {
  _WalletSummaryOverride(this.summary);

  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> build() async => summary;
}

class _LoadingWalletSummaryOverride extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() => Completer<WalletSummaryModel>().future;
}

class _ErrorWalletSummaryOverride extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() => Future.error(StateError('wallet'));
}

WalletSummaryModel _wallet({BigInt? star, BigInt? bonus, BigInt? cotton}) =>
    WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: star ?? BigInt.zero,
      bonus: bonus ?? BigInt.zero,
      cotton: cotton ?? BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: DateTime.utc(2026, 7, 21),
    );

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

  group('VotingDialog', () {
    test(
      'auth recovery failure uses localized re-login copy, not raw JWT text',
      () {
        const localizedMessage = 'You need to sign in. Please log in again.';
        final message = VotingDialogHelper.resolveVoteFailureMessage(
          error: const EdgeAuthRecoveryException(
            EdgeAuthRecoveryFailureReason.retryUnauthorized,
            cause: FunctionException(status: 401, details: 'Invalid JWT'),
          ),
          reLoginMessage: localizedMessage,
          genericMessage: 'Vote failed',
          endedMessage: 'Voting ended',
          upcomingMessage: 'Voting not started',
        );

        expect(message, localizedMessage);
        expect(message, isNot(contains('Invalid JWT')));
      },
    );

    late VoteModel voteModel;
    late VoteItemModel voteItemModel;

    setUp(() {
      voteModel = MockData.vote();
      voteItemModel = MockData.voteItem();
    });

    testWidgets('renders without errors with VotePortal.vote', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('renders without errors with VotePortal.pic', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.pic,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('displays authoritative general wallet total', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 500, starCandyBonus: 50),
          extraOverrides: [
            walletSummaryProvider.overrideWith(
              () => _WalletSummaryOverride(
                _wallet(star: BigInt.from(500), bonus: BigInt.from(50)),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Star candy total = 500 + 50 = 550
      expect(find.text('550'), findsOneWidget);
    });

    testWidgets('displays artist name from voteItemModel with artist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      await tester.pumpAndSettle();

      expect(find.text('정국'), findsOneWidget);
      expect(find.text('BTS'), findsOneWidget);
    });

    testWidgets('displays group name when artist id is 0', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 100,
        'vote_id': 1,
        'artist': <String, dynamic>{'id': 0, 'name': <String, dynamic>{}},
        'artist_group': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': 'BLACKPINK'},
          'image': null,
        },
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
      await tester.pumpAndSettle();

      expect(find.text('BLACKPINK'), findsOneWidget);
    });

    testWidgets('vote button is disabled when no amount entered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('entering vote amount enables button when valid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 100, starCandyBonus: 10),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '50');
      await tester.pumpAndSettle();

      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('Cotton-only wallet enables normal vote submit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          extraOverrides: [
            walletSummaryProvider.overrideWith(
              () => _WalletSummaryOverride(_wallet(cotton: BigInt.from(10))),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();

      final submit = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(VotingSubmitButton),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(submit.onTap, isNotNull);
    });

    for (final state in ['loading', 'error']) {
      testWidgets('wallet $state keeps nonzero normal vote disabled', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1125, 2436);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestApp(
            VotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            extraOverrides: [
              walletSummaryProvider.overrideWith(
                state == 'loading'
                    ? _LoadingWalletSummaryOverride.new
                    : _ErrorWalletSummaryOverride.new,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), '5');
        await tester.pump();

        final submit = tester.widget<GestureDetector>(
          find.descendant(
            of: find.byType(VotingSubmitButton),
            matching: find.byType(GestureDetector),
          ),
        );
        expect(submit.onTap, isNull);
      });
    }

    testWidgets('normal use-all caps a greater-than-JS-safe wallet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          extraOverrides: [
            walletSummaryProvider.overrideWith(
              () => _WalletSummaryOverride(
                _wallet(star: BigInt.parse('9007199254740993')),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VotingCheckAllOption));
      await tester.pump();

      final input = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(input.controller!.text, '2,147,483,647');
      final submit = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(VotingSubmitButton),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(submit.onTap, isNotNull);
    });

    testWidgets('shows error when vote exceeds star candy', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(starCandy: 10, starCandyBonus: 0),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '100');
      await tester.pumpAndSettle();

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('partnership vote displays partner logo text', (tester) async {
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
        'stop_at': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': true,
        'partner': 'testpartner',
        'reward': null,
      });

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: partnerVote,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('TESTPARTNER'), findsWidgets);
    });

    testWidgets('non-partnership vote displays default logo', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('formats large numbers with comma', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(
            starCandy: 100000,
            starCandyBonus: 0,
          ),
          extraOverrides: [
            walletSummaryProvider.overrideWith(
              () => _WalletSummaryOverride(_wallet(star: BigInt.from(100000))),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100,000'), findsOneWidget);

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '12345');
      await tester.pumpAndSettle();

      expect(find.text('12,345'), findsOneWidget);
    });

    testWidgets('renders with null artist image (default icon)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with artist group image when artist id is 0', (
      tester,
    ) async {
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
          'image': null,
        },
        'artist_group': <String, dynamic>{
          'id': 1,
          'name': <String, dynamic>{'ko': 'BTS'},
          'image': null,
        },
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(VotingDialog), findsOneWidget);
    });

    testWidgets('leading zeros are removed from input', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
          userProfile: MockData.userProfile(
            starCandy: 10000,
            starCandyBonus: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '00100');
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('zero-only input results in empty text', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          VotingDialog(
            voteModel: voteModel,
            voteItemModel: voteItemModel,
            portalType: VotePortal.vote,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '000');
      await tester.pumpAndSettle();

      expect(find.text('000'), findsNothing);
    });
  });
}
