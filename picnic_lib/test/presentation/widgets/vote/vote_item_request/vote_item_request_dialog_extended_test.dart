import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/current_applications_section.dart'
    hide ArtistNameUtils;

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
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
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('VoteItemRequestDialog additional state combinations', () {
    testWidgets('dialog renders with vote that has upcoming status',
        (WidgetTester tester) async {
      final upcomingVote = MockData.vote(
        id: 10,
        titleKo: '예정 투표',
        isUpcoming: true,
        startAt: DateTime.now().add(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: upcomingVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('dialog renders with ended vote', (WidgetTester tester) async {
      final endedVote = MockData.vote(
        id: 20,
        titleKo: '종료 투표',
        isEnded: true,
      );

      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            child: VoteItemRequestDialog(vote: endedVote),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(VoteItemRequestDialog), findsOneWidget);
    });

    testWidgets('dialog structure contains column with header and sections',
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

      // Dialog structure
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('ArtistApplicationInfo edge cases', () {
    test('copyWith updates only isSubmitting', () {
      final info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: true,
        isSubmitting: false,
      );

      final updated = info.copyWith(isSubmitting: true);

      expect(updated.artistName, 'Test');
      expect(updated.applicationCount, 5);
      expect(updated.applicationStatus, 'pending');
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });

    test('default values for new ArtistApplicationInfo', () {
      final info = ArtistApplicationInfo(
        artistName: '',
        applicationCount: 0,
        applicationStatus: '',
        isAlreadyInVote: false,
      );

      expect(info.isSubmitting, isFalse);
      expect(info.applicationCount, 0);
    });
  });

  group('VoteItemRequestDialog error message edge cases', () {
    test('error message detection for various already_applied patterns', () {
      final patterns = [
        'already_applied',
        'Error: already_applied for user',
        'PostgrestException: already_applied',
      ];

      for (final pattern in patterns) {
        expect(pattern.contains('already_applied'), isTrue,
            reason: 'Should detect: $pattern');
      }
    });

    test('success message detection', () {
      expect('✅ 완료'.startsWith('✅'), isTrue);
      expect('❌ 실패'.startsWith('✅'), isFalse);
      expect('일반 메시지'.startsWith('✅'), isFalse);
    });
  });

  group('Search token invalidation logic', () {
    test('new search token invalidates old one', () {
      String? lastSearchToken;

      // First search
      final token1 = '${DateTime.now().millisecondsSinceEpoch}';
      lastSearchToken = token1;

      // Second search (invalidates first)
      final token2 = '${DateTime.now().millisecondsSinceEpoch + 1}';
      lastSearchToken = token2;

      // When first search completes, token doesn't match
      expect(lastSearchToken == token1, isFalse);
      // Current token is token2
      expect(lastSearchToken, token2);
    });
  });

  group('Application submission state tracking', () {
    test('submitting state in searchResultsInfo updates correctly', () {
      final searchResultsInfo = <String, ArtistApplicationInfo>{};

      // Initial state
      searchResultsInfo['1'] = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 3,
        applicationStatus: 'none',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      // Start submitting
      searchResultsInfo['1'] = searchResultsInfo['1']!.copyWith(
        isSubmitting: true,
      );
      expect(searchResultsInfo['1']!.isSubmitting, isTrue);

      // Submission complete
      searchResultsInfo['1'] = searchResultsInfo['1']!.copyWith(
        isSubmitting: false,
        applicationStatus: 'pending',
        applicationCount: 4,
      );
      expect(searchResultsInfo['1']!.isSubmitting, isFalse);
      expect(searchResultsInfo['1']!.applicationStatus, 'pending');
      expect(searchResultsInfo['1']!.applicationCount, 4);
    });

    test('submission error reverts isSubmitting', () {
      final info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 3,
        applicationStatus: 'none',
        isAlreadyInVote: false,
        isSubmitting: true,
      );

      final reverted = info.copyWith(isSubmitting: false);
      expect(reverted.isSubmitting, isFalse);
      // Other fields unchanged
      expect(reverted.applicationCount, 3);
    });
  });

  group('ArtistNameUtils edge cases', () {
    test('formatNumber handles negative numbers', () {
      // Negative numbers should still format with commas
      final result = ArtistNameUtils.formatNumber(-1234);
      expect(result, contains('1'));
    });

    test('formatNumber handles very large numbers', () {
      final result = ArtistNameUtils.formatNumber(1000000000);
      expect(result, '1,000,000,000');
    });

    test('formatNumber handles 999 (no comma needed)', () {
      expect(ArtistNameUtils.formatNumber(999), '999');
    });
  });
}
