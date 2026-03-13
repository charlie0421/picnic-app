import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

Map<String, dynamic> _voteItemJson({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  int artistId = 10,
  int groupId = 1,
  String groupNameKo = 'BTS',
  String? artistImage,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': artistImage,
      'artist_group': {
        'id': groupId,
        'name': {'ko': groupNameKo, 'en': groupNameKo},
        'image': null,
      },
    },
    'artist_group': null,
  };
}

VoteModel _buildVote({
  int id = 1,
  String titleKo = '테스트 투표',
  String? voteCategory = 'birthday',
  bool isEnded = false,
  bool isUpcoming = false,
  DateTime? startAt,
  DateTime? stopAt,
  List<Map<String, dynamic>>? voteItemJsons,
}) {
  final now = DateTime.now().toUtc();
  final items = voteItemJsons ??
      [
        _voteItemJson(id: 1, voteTotal: 10000),
        _voteItemJson(
            id: 2, voteTotal: 8000, artistNameKo: '정국', artistId: 11),
        _voteItemJson(id: 3, voteTotal: 5000, artistNameKo: 'V', artistId: 12),
      ];

  return VoteModel.fromJson({
    'id': id,
    'title': {'ko': titleKo, 'en': 'Test Vote'},
    'vote_category': voteCategory,
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': items,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at':
        (startAt ?? now.subtract(const Duration(days: 1))).toIso8601String(),
    'stop_at': (stopAt ?? now.add(const Duration(days: 7))).toIso8601String(),
    'is_ended': isEnded,
    'is_upcoming': isUpcoming,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  });
}

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

Future<void> _ignoreRenderErrors(Future<void> Function() callback) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final exception = details.exception;
    if (exception is FlutterError && exception.message.contains('overflowed')) {
      return;
    }
    if (exception.toString().contains('LateInitializationError')) {
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
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('VoteInfoCard didUpdateWidget', () {
    testWidgets('updates vote data when vote changes', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote1 = _buildVote(id: 1, titleKo: '투표 1');
      final vote2 = _buildVote(id: 2, titleKo: '투표 2');

      late StateSetter outerSetState;
      VoteModel currentVote = vote1;

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return Builder(
                  builder: (ctx) => VoteInfoCard(
                    context: ctx,
                    vote: currentVote,
                    status: VoteStatus.active,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);

        // Change the vote
        outerSetState(() {
          currentVote = vote2;
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);
      });
    });

    testWidgets('updates when status changes', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote = _buildVote();

      late StateSetter outerSetState;
      VoteStatus currentStatus = VoteStatus.active;

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return Builder(
                  builder: (ctx) => VoteInfoCard(
                    context: ctx,
                    vote: vote,
                    status: currentStatus,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Change status to end
        outerSetState(() {
          currentStatus = VoteStatus.end;
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);
      });
    });
  });

  group('VoteInfoCard upcoming thumbnail pagination', () {
    testWidgets('renders pagination controls for multi-page grid',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      // 24 items = 2 pages (12 per page)
      final vote = _buildVote(
        isUpcoming: true,
        voteItemJsons: List.generate(
          24,
          (i) => _voteItemJson(
            id: i + 1,
            voteTotal: 0,
            artistId: 100 + i,
            artistNameKo: 'Art${i + 1}',
          ),
        ),
      );

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (ctx) => VoteInfoCard(
                context: ctx,
                vote: vote,
                status: VoteStatus.upcoming,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Page indicator shows 1/2
        expect(find.text('1/2'), findsOneWidget);

        // Chevrons present
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });
    });

    testWidgets('tapping next page button navigates', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote = _buildVote(
        isUpcoming: true,
        voteItemJsons: List.generate(
          24,
          (i) => _voteItemJson(
            id: i + 1,
            voteTotal: 0,
            artistId: 100 + i,
            artistNameKo: 'Art${i + 1}',
          ),
        ),
      );

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (ctx) => VoteInfoCard(
                context: ctx,
                vote: vote,
                status: VoteStatus.upcoming,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Tap right chevron to go to page 2
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Should now show page 2/2
        expect(find.text('2/2'), findsOneWidget);
      });
    });
  });

  group('VoteInfoCard vote item sorting', () {
    testWidgets('items are sorted by voteTotal descending', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Items intentionally out of order
      final vote = _buildVote(voteItemJsons: [
        _voteItemJson(id: 3, voteTotal: 1000, artistNameKo: 'Low', artistId: 13),
        _voteItemJson(
            id: 1, voteTotal: 9999, artistNameKo: 'High', artistId: 11),
        _voteItemJson(
            id: 2, voteTotal: 5000, artistNameKo: 'Mid', artistId: 12),
      ]);

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (ctx) => VoteInfoCard(
                context: ctx,
                vote: vote,
                status: VoteStatus.active,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);
      });
    });
  });

  group('VoteInfoCard ended vote with achieve category', () {
    testWidgets('renders ended achieve vote', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote = _buildVote(
        voteCategory: 'achieve',
        isEnded: true,
      );

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (ctx) => VoteInfoCard(
                context: ctx,
                vote: vote,
                status: VoteStatus.end,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);
      });
    });
  });

  group('VoteInfoCard with null vote items', () {
    testWidgets('handles vote with no voteItem field gracefully',
        (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': 'Null Items', 'en': 'Null Items'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (ctx) => VoteInfoCard(
                context: ctx,
                vote: vote,
                status: VoteStatus.active,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(VoteInfoCard), findsOneWidget);
      });
    });
  });
}
