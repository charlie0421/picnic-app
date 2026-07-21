import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/current_applications_section.dart'
    hide ArtistNameUtils;
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_and_results_section.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class FailingVoteItemRequestService extends Fake
    implements VoteItemRequestService {
  FailingVoteItemRequestService({
    this.failInitial = false,
    this.failSearch = false,
  });

  final bool failInitial;
  final bool failSearch;

  @override
  Future<Map<String, dynamic>> loadAllApplicationsByArtist() async {
    if (failInitial) throw Exception('internal table detail');
    return {
      'artistApplicationSummaries': <Map<String, dynamic>>[],
      'totalApplications': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> searchArtistsWithPagination(
    String query, {
    required int page,
    required int pageSize,
  }) async {
    if (failSearch) throw Exception('internal table detail');
    return {'artists': <dynamic>[], 'hasMore': false, 'currentPage': page};
  }
}

void main() {
  late void Function() restore;
  late VoteModel testVote;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'vote_item_request_users': <Map<String, dynamic>>[],
      'vote_item': <Map<String, dynamic>>[],
      'vote_requests': <Map<String, dynamic>>[],
      'vote_item_request_count': <Map<String, dynamic>>[
        {'count': 0},
      ],
    });
    testVote = MockData.vote(id: 1, titleKo: '테스트 투표', titleEn: 'Test Vote');
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('VoteItemRequestDialog render - logged in states', () {
    testWidgets(
      'shows a generic error and stops loading when initial load fails',
      (WidgetTester tester) async {
        final service = FailingVoteItemRequestService(failInitial: true);

        await tester.pumpWidget(
          buildTestAppPage(
            Material(
              child: VoteItemRequestDialog(vote: testVote, service: service),
            ),
            loggedIn: true,
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(VoteItemRequestDialog)),
            ).message_error_occurred,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('internal table detail'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('shows a generic error and stops searching when search fails', (
      WidgetTester tester,
    ) async {
      final service = FailingVoteItemRequestService(failSearch: true);

      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote, service: service),
          ),
          loggedIn: true,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'artist');
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(VoteItemRequestDialog)),
          ).common_text_search_error,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('internal table detail'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders all main sections when logged in', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: testVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
      expect(find.byType(SearchAndResultsSection), findsOneWidget);
      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: testVote)),
          loggedIn: true,
          locale: const Locale('en'),
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: testVote)),
          loggedIn: true,
          locale: const Locale('ja'),
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });
  });

  group('VoteItemRequestDialog render - logged out states', () {
    testWidgets('renders when not logged in', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: testVote)),
          loggedIn: false,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });
  });

  group('VoteItemRequestDialog render - vote variants', () {
    testWidgets('renders with upcoming vote', (WidgetTester tester) async {
      final upcomingVote = MockData.vote(
        id: 10,
        titleKo: '예정 투표',
        isUpcoming: true,
        startAt: DateTime.now().add(const Duration(days: 3)),
      );

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: upcomingVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('renders with ended vote', (WidgetTester tester) async {
      final endedVote = MockData.vote(id: 20, titleKo: '종료 투표', isEnded: true);

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: endedVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('renders with birthday category vote', (
      WidgetTester tester,
    ) async {
      final birthdayVote = MockData.vote(
        id: 30,
        titleKo: '생일 축하 투표',
        voteCategory: 'birthday',
      );

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: birthdayVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('renders with null category vote', (WidgetTester tester) async {
      final noCategoryVote = MockData.vote(
        id: 40,
        titleKo: '카테고리 없는 투표',
        voteCategory: null,
      );

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: noCategoryVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });
  });

  group('VoteItemRequestDialog render - with mock application data', () {
    testWidgets('renders with existing application summaries from mock', (
      WidgetTester tester,
    ) async {
      setupMockSupabase({
        'vote_item_request_users': <Map<String, dynamic>>[
          {
            'id': 'req-1',
            'vote_id': 1,
            'artist_id': 10,
            'user_id': 'user-1',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          },
        ],
        'vote_item': <Map<String, dynamic>>[],
        'vote_requests': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          Material(child: VoteItemRequestDialog(vote: testVote)),
          loggedIn: true,
        ),
      );

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });
  });

  group('VoteItemRequestDialog render - showVoteItemRequestDialog', () {
    testWidgets('opens and closes dialog via function', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showVoteItemRequestDialog(
                context: context,
                voteModel: testVote,
              ),
              child: const Text('Open'),
            ),
          ),
          loggedIn: true,
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(VoteItemRequestDialog), findsNothing);
    });

    testWidgets('dialog is barrier dismissible', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showVoteItemRequestDialog(
                context: context,
                voteModel: testVote,
              ),
              child: const Text('Open'),
            ),
          ),
          loggedIn: true,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(VoteItemRequestDialog), findsNothing);
    });
  });

  group('CurrentApplicationsSection render', () {
    testWidgets('renders loading state with shimmer', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: CurrentApplicationsSection(
              artistApplicationSummaries: [],
              totalApplications: 0,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
    });

    testWidgets('renders empty state with no applications', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: CurrentApplicationsSection(
              artistApplicationSummaries: [],
              totalApplications: 0,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders with application summaries', (
      WidgetTester tester,
    ) async {
      final summaries = <Map<String, dynamic>>[
        {
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
          'pendingCount': 5,
          'approvedCount': 0,
          'rejectedCount': 0,
        },
        {
          'artist': {
            'id': 11,
            'name': {'ko': '정국', 'en': 'Jungkook'},
            'image': null,
            'artist_group': null,
          },
          'pendingCount': 0,
          'approvedCount': 3,
          'rejectedCount': 0,
        },
        {
          'artist': {
            'id': 12,
            'name': {'ko': '뷔', 'en': 'V'},
            'image': null,
            'artist_group': null,
          },
          'pendingCount': 0,
          'approvedCount': 0,
          'rejectedCount': 2,
        },
      ];

      await pumpAndDrain(
        tester,
        buildTestApp(
          Expanded(
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 10,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });

    testWidgets('renders with null artist data in summary', (
      WidgetTester tester,
    ) async {
      final summaries = <Map<String, dynamic>>[
        {
          'artist': null,
          'pendingCount': 1,
          'approvedCount': 0,
          'rejectedCount': 0,
        },
      ];

      await pumpAndDrain(
        tester,
        buildTestApp(
          Expanded(
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 1,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      expect(find.text('알 수 없는 아티스트'), findsOneWidget);
    });

    testWidgets('renders mixed status counts correctly', (
      WidgetTester tester,
    ) async {
      final summaries = <Map<String, dynamic>>[
        {
          'artist': {
            'id': 10,
            'name': {'ko': '혼합 아티스트', 'en': 'Mixed'},
            'image': null,
            'artist_group': null,
          },
          'pendingCount': 2,
          'approvedCount': 1,
          'rejectedCount': 1,
        },
      ];

      await pumpAndDrain(
        tester,
        buildTestApp(
          Expanded(
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 4,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });
  });
}
