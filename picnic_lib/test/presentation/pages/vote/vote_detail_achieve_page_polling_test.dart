import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({bool isEnded = false}) {
  final now = DateTime.now().toUtc();
  return {
    'id': 1,
    'title': {'ko': '달성 투표', 'en': 'Achievement Vote'},
    'vote_category': 'achieve',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at':
        (isEnded
                ? now.subtract(const Duration(days: 1))
                : now.add(const Duration(days: 7)))
            .toIso8601String(),
    'is_ended': isEnded,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow() => {
  'id': 1,
  'vote_id': 1,
  'vote_total': 5000,
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
};

Map<String, dynamic> _voteAchieveRow() => {
  'id': 1,
  'vote_id': 1,
  'reward_id': 1,
  'order': 1,
  'amount': 10000,
  'reward': {
    'id': 1,
    'title': {'ko': '포토카드'},
    'thumbnail': null,
  },
  'vote': _voteRow(),
};

class _VoteHttpHarness {
  _VoteHttpHarness({this.isEnded = false});

  final bool isEnded;
  final Completer<http.Response> achievementResponse = Completer();
  final Completer<http.Response> totalsResponse = Completer();

  bool holdAchievements = false;
  bool holdTotals = false;
  int achievementFailuresRemaining = 0;
  int itemFailuresRemaining = 0;
  int achievementRequests = 0;
  int fullItemRequests = 0;
  int totalOnlyRequests = 0;
  String? lastTotalsTable;

  void install() {
    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: MockClient(_handle),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    if (path.contains('/auth/')) {
      return _json({'error': 'not authenticated'}, request, statusCode: 401);
    }
    if (!path.contains('/rest/v1/')) {
      return _json(<String, dynamic>{}, request);
    }

    final table = path.split('/rest/v1/').last.split('?').first;
    switch (table) {
      case 'vote':
      case 'pic_vote':
        return _json(_voteRow(isEnded: isEnded), request);
      case 'vote_item':
      case 'pic_vote_item':
        final select = request.url.queryParameters['select'] ?? '';
        if (select == 'id,vote_total') {
          totalOnlyRequests++;
          lastTotalsTable = table;
          if (holdTotals) return totalsResponse.future;
          return _json([
            {'id': 1, 'vote_total': 5000},
          ], request);
        }
        fullItemRequests++;
        if (itemFailuresRemaining > 0) {
          itemFailuresRemaining--;
          return _json(
            {'message': 'temporary item failure'},
            request,
            statusCode: 503,
          );
        }
        return _json([_voteItemRow()], request);
      case 'vote_achieve':
        achievementRequests++;
        if (holdAchievements) return achievementResponse.future;
        if (achievementFailuresRemaining > 0) {
          achievementFailuresRemaining--;
          return _json(
            {'message': 'temporary achievement failure'},
            request,
            statusCode: 503,
          );
        }
        return _json([_voteAchieveRow()], request);
      default:
        return _json(<dynamic>[], request);
    }
  }

  http.Response _json(
    Object body,
    http.Request request, {
    int statusCode = 200,
  }) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      request: request,
      headers: const {
        'content-type': 'application/json',
        'content-range': '0-0/*',
      },
    );
  }

  void completeAchievements() {
    if (!achievementResponse.isCompleted) {
      achievementResponse.complete(
        _json([_voteAchieveRow()], http.Request('GET', Uri())),
      );
    }
  }

  void completeTotals({int voteTotal = 5000}) {
    if (!totalsResponse.isCompleted) {
      totalsResponse.complete(
        _json([
          {'id': 1, 'vote_total': voteTotal},
        ], http.Request('GET', Uri())),
      );
    }
  }

  void resetPollCounts() {
    fullItemRequests = 0;
    totalOnlyRequests = 0;
    lastTotalsTable = null;
  }
}

void main() {
  late void Function() restoreImageErrors;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restoreImageErrors = suppressImageErrors();
  });

  tearDown(() {
    restoreImageErrors();
    testSupabaseClient = null;
  });

  Future<void> pumpPage(
    WidgetTester tester,
    _VoteHttpHarness harness, {
    VotePortal votePortal = VotePortal.vote,
  }) async {
    harness.install();
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        VoteDetailAchievePage(voteId: 1, votePortal: votePortal),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // BannerAdWidget owns a non-cancellable retry chain (up to 25 seconds).
    // Advance one retry at a time: its next Timer is scheduled by a microtask
    // after each pump, so one large duration cannot drain the whole chain.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 30));
      drainExpectedImageErrors(tester);
    }
  }

  testWidgets('all builds share one successful achievement request', (
    tester,
  ) async {
    final harness = _VoteHttpHarness();

    await pumpPage(tester, harness);
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      harness.achievementRequests,
      1,
      reason: 'the ladder and progress bar must consume the same future',
    );

    await disposePage(tester);
  });

  testWidgets('pending achievement request stays single-flight across ticks', (
    tester,
  ) async {
    final harness = _VoteHttpHarness()..holdAchievements = true;

    await pumpPage(tester, harness);
    await tester.pump(const Duration(seconds: 3));

    expect(harness.achievementRequests, 1);

    await disposePage(tester);
    harness.completeAchievements();
    await tester.pump();
  });

  testWidgets('temporary achievement failure retries on the next live tick', (
    tester,
  ) async {
    final harness = _VoteHttpHarness()..achievementFailuresRemaining = 1;

    await pumpPage(tester, harness);
    expect(harness.achievementRequests, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(harness.achievementRequests, 2);

    await disposePage(tester);
  });

  testWidgets('poll requests only id and vote_total', (tester) async {
    final harness = _VoteHttpHarness();
    await pumpPage(tester, harness);
    harness.resetPollCounts();

    await tester.pump(const Duration(seconds: 1));

    expect(harness.totalOnlyRequests, 1);
    expect(
      harness.fullItemRequests,
      0,
      reason: 'polling must not reload artist and artist_group joins',
    );

    await disposePage(tester);
  });

  testWidgets(
    'failed initial items show retry and recover with one full fetch',
    (tester) async {
      final harness = _VoteHttpHarness()..itemFailuresRemaining = 1;
      await pumpPage(tester, harness);
      final retry = find.byKey(const Key('achieve-items-retry'));
      expect(retry, findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(harness.fullItemRequests, 1);
      expect(harness.totalOnlyRequests, 0);

      final button = tester.widget<TextButton>(retry);
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.fullItemRequests, 2);
      expect(retry, findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await disposePage(tester);
    },
  );

  testWidgets(
    'manual refresh recovers hung poll and ignores its late response',
    (tester) async {
      final harness = _VoteHttpHarness()..holdTotals = true;
      await pumpPage(tester, harness);
      await tester.pump(const Duration(seconds: 20));
      expect(harness.totalOnlyRequests, 1);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(VoteDetailAchievePage)),
      );

      harness.holdTotals = false;
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      final refreshDone = refresh.onRefresh();
      await tester.pump();
      await refreshDone;
      await tester.pump(const Duration(seconds: 1));
      expect(harness.fullItemRequests, 2);
      expect(harness.totalOnlyRequests, 2);

      harness.completeTotals(voteTotal: 9999);
      await tester.pump();
      expect(
        container
            .read(
              asyncVoteItemListProvider(voteId: 1, votePortal: VotePortal.vote),
            )
            .value!
            .first!
            .voteTotal,
        5000,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(harness.totalOnlyRequests, 3);
      await disposePage(tester);
    },
  );

  testWidgets('pending total refresh stays single-flight across ticks', (
    tester,
  ) async {
    final harness = _VoteHttpHarness()..holdTotals = true;
    await pumpPage(tester, harness);
    harness.resetPollCounts();

    await tester.pump(const Duration(seconds: 3));

    expect(harness.totalOnlyRequests, 1);
    expect(harness.fullItemRequests, 0);

    await disposePage(tester);
    harness.completeTotals();
    await tester.pump();
  });

  testWidgets('pic portal polls the pic vote-item provider instance', (
    tester,
  ) async {
    final harness = _VoteHttpHarness();
    await pumpPage(tester, harness, votePortal: VotePortal.pic);
    harness.resetPollCounts();

    await tester.pump(const Duration(seconds: 1));

    expect(harness.totalOnlyRequests, 1);
    expect(harness.lastTotalsTable, 'pic_vote_item');
    expect(harness.fullItemRequests, 0);

    await disposePage(tester);
  });

  testWidgets('polling pauses while scrolling and refreshes once on settle', (
    tester,
  ) async {
    final harness = _VoteHttpHarness();
    await pumpPage(tester, harness);
    harness.resetPollCounts();

    final scrollable = find.byType(SingleChildScrollView).last;
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(harness.totalOnlyRequests + harness.fullItemRequests, 0);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.totalOnlyRequests, 1);
    expect(harness.fullItemRequests, 0);

    await disposePage(tester);
  });

  testWidgets('ended vote polls on the five-second cadence', (tester) async {
    final harness = _VoteHttpHarness(isEnded: true);
    await pumpPage(tester, harness);
    harness.resetPollCounts();

    await tester.pump(const Duration(seconds: 4));
    expect(harness.totalOnlyRequests + harness.fullItemRequests, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(harness.totalOnlyRequests, 1);
    expect(harness.fullItemRequests, 0);

    await disposePage(tester);
  });

  testWidgets('pause and dispose schedule no further polling work', (
    tester,
  ) async {
    final harness = _VoteHttpHarness();
    await pumpPage(tester, harness);
    harness.resetPollCounts();

    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(harness.totalOnlyRequests + harness.fullItemRequests, 0);

    await disposePage(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(harness.totalOnlyRequests + harness.fullItemRequests, 0);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
