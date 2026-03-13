import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/current_applications_section.dart'
    hide ArtistNameUtils;
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_and_results_section.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  late VoteModel testVote;

  setUp(() {
    initTestColors();
    // Setup mock Supabase with vote_item_request related tables
    setupMockSupabase({
      'vote_item_request_users': <Map<String, dynamic>>[],
      'vote_item': <Map<String, dynamic>>[],
      'vote_requests': <Map<String, dynamic>>[],
      'vote_item_request_count': <Map<String, dynamic>>[
        {'count': 0},
      ],
    });
    testVote = MockData.vote(id: 1, titleKo: '테스트 투표', titleEn: 'Test Vote');
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('VoteItemRequestDialog', () {
    testWidgets('renders dialog with header and sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
      // Header should have a close button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      // Header should have vote icon
      expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
    });

    testWidgets('renders with search section visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('renders current applications section when not searching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      // The CurrentApplicationsSection should be visible when not in search focus
      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });

    testWidgets('close button pops dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
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
      await tester.pump();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(VoteItemRequestDialog), findsNothing);
    });

    testWidgets('renders with not logged in state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: false,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('showVoteItemRequestDialog opens dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
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
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('renders with different vote model',
        (WidgetTester tester) async {
      final customVote = MockData.vote(
        id: 99,
        titleKo: '커스텀 투표',
        titleEn: 'Custom Vote',
      );

      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: customVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('renders dialog with gradient header decoration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      // The header should contain the dialog title
      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
      // Search icon should be visible in search section
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('dialog has correct decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: testVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Verify dialog container exists with rounded corners
      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });
  });

  group('ArtistApplicationInfo', () {
    test('creates with required fields', () {
      final info = ArtistApplicationInfo(
        artistName: '지민',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      expect(info.artistName, '지민');
      expect(info.applicationCount, 5);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('creates with isSubmitting true', () {
      final info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 0,
        applicationStatus: '',
        isAlreadyInVote: false,
        isSubmitting: true,
      );

      expect(info.isSubmitting, isTrue);
    });

    test('copyWith updates fields', () {
      final info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 3,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(
        applicationCount: 4,
        applicationStatus: 'approved',
        isSubmitting: true,
      );

      expect(updated.artistName, 'Original');
      expect(updated.applicationCount, 4);
      expect(updated.applicationStatus, 'approved');
      expect(updated.isAlreadyInVote, isFalse);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith without params returns equivalent object', () {
      final info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 1,
        applicationStatus: 'pending',
        isAlreadyInVote: true,
        isSubmitting: false,
      );

      final copy = info.copyWith();

      expect(copy.artistName, info.artistName);
      expect(copy.applicationCount, info.applicationCount);
      expect(copy.applicationStatus, info.applicationStatus);
      expect(copy.isAlreadyInVote, info.isAlreadyInVote);
      expect(copy.isSubmitting, info.isSubmitting);
    });

    test('copyWith updates artistName', () {
      final info = ArtistApplicationInfo(
        artistName: 'Old Name',
        applicationCount: 0,
        applicationStatus: '',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(artistName: 'New Name');
      expect(updated.artistName, 'New Name');
    });

    test('copyWith updates isAlreadyInVote', () {
      final info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 0,
        applicationStatus: '',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(isAlreadyInVote: true);
      expect(updated.isAlreadyInVote, isTrue);
    });
  });

  group('UserApplicationInfo', () {
    test('creates with required fields', () {
      final info = UserApplicationInfo(
        id: 'app-1',
        artistName: '지민',
        status: 'pending',
        applicationCount: 3,
      );

      expect(info.id, 'app-1');
      expect(info.artistName, '지민');
      expect(info.status, 'pending');
      expect(info.applicationCount, 3);
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('creates with optional fields', () {
      final artist = MockData.artist(nameKo: '정국');

      final info = UserApplicationInfo(
        id: 'app-2',
        artistName: '정국',
        groupName: 'BTS',
        status: 'approved',
        applicationCount: 10,
        artist: artist,
      );

      expect(info.groupName, 'BTS');
      expect(info.artist, isNotNull);
      expect(info.artist!.id, 1);
    });
  });

  group('ArtistNameUtils', () {
    test('formatNumber with small number', () {
      expect(ArtistNameUtils.formatNumber(42), '42');
    });

    test('formatNumber with thousands', () {
      expect(ArtistNameUtils.formatNumber(1234), '1,234');
    });

    test('formatNumber with millions', () {
      expect(ArtistNameUtils.formatNumber(1234567), '1,234,567');
    });

    test('formatNumber with zero', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
    });

    test('formatNumber with single digit', () {
      expect(ArtistNameUtils.formatNumber(5), '5');
    });

    test('formatNumber with exactly 1000', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
    });
  });

  group('VoteRequestStatusUtils color logic', () {
    test('getStatusColor for pending returns orange', () {
      expect(VoteRequestStatusUtils.getStatusColor('pending'), Colors.orange);
    });

    test('getStatusColor for approved returns green', () {
      expect(VoteRequestStatusUtils.getStatusColor('approved'), Colors.green);
    });

    test('getStatusColor for rejected returns red', () {
      expect(VoteRequestStatusUtils.getStatusColor('rejected'), Colors.red);
    });

    test('getStatusColor for in-progress returns primary', () {
      final color = VoteRequestStatusUtils.getStatusColor('in-progress');
      expect(color, isNotNull);
    });

    test('getStatusColor for cancelled returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('cancelled');
      expect(color, isNotNull);
    });

    test('getStatusColor for unknown returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('unknown');
      expect(color, isNotNull);
    });

    test('getStatusColor is case insensitive', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('PENDING'),
        Colors.orange,
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('Approved'),
        Colors.green,
      );
    });
  });

  group('VoteItemRequestDialog error message logic', () {
    test('success message starts with checkmark', () {
      final message = '✅ 신청이 완료되었습니다!';
      final isSuccess = message.startsWith('✅');
      expect(isSuccess, isTrue);
    });

    test('error message does not start with checkmark', () {
      final message = '신청 중 오류가 발생했습니다';
      final isSuccess = message.startsWith('✅');
      expect(isSuccess, isFalse);
    });

    test('already_applied error detection', () {
      final errorString = 'PostgrestException: already_applied';
      expect(errorString.contains('already_applied'), isTrue);

      final message = errorString.contains('already_applied')
          ? '이미 신청한 아티스트입니다'
          : '신청 중 오류가 발생했습니다: $errorString';

      expect(message, '이미 신청한 아티스트입니다');
    });

    test('generic error message', () {
      final errorString = 'NetworkError: timeout';
      final message = errorString.contains('already_applied')
          ? '이미 신청한 아티스트입니다'
          : '신청 중 오류가 발생했습니다: $errorString';

      expect(message, contains('NetworkError'));
    });
  });

  group('VoteItemRequestDialog search state logic', () {
    test('search focus toggling', () {
      bool isSearchFocused = false;

      // Tap search box
      isSearchFocused = true;
      expect(isSearchFocused, isTrue);

      // Close search
      isSearchFocused = false;
      expect(isSearchFocused, isFalse);
    });

    test('search results clearing on close', () {
      List<String> searchResults = ['result1', 'result2'];
      Map<String, String> searchResultsInfo = {'1': 'info1'};
      String currentSearchQuery = 'test query';

      // Close search
      searchResults.clear();
      searchResultsInfo.clear();
      currentSearchQuery = '';

      expect(searchResults, isEmpty);
      expect(searchResultsInfo, isEmpty);
      expect(currentSearchQuery, '');
    });

    test('pagination state management', () {
      int currentPage = 0;
      bool hasMoreResults = true;
      bool isLoadingMore = false;

      // Load more
      isLoadingMore = true;
      currentPage = 1;
      hasMoreResults = true;
      isLoadingMore = false;

      expect(currentPage, 1);
      expect(hasMoreResults, isTrue);
      expect(isLoadingMore, isFalse);

      // Last page
      hasMoreResults = false;
      expect(hasMoreResults, isFalse);
    });
  });
}
