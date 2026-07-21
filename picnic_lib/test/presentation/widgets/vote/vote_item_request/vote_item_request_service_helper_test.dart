import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper.dart';

int _queryCount(int artistCount, bool hasUser) {
  return VoteItemRequestServiceHelper.estimateEnrichmentQueryCount(
    artistCount: artistCount,
    hasUser: hasUser,
  );
}

void main() {
  // ===========================================================================
  // Pagination
  // ===========================================================================
  group('hasMoreResults', () {
    test('returns true when resultCount equals pageSize', () {
      expect(VoteItemRequestServiceHelper.hasMoreResults(20, 20), isTrue);
    });

    test('returns false when resultCount is less than pageSize', () {
      expect(VoteItemRequestServiceHelper.hasMoreResults(15, 20), isFalse);
    });

    test('returns false when resultCount is zero', () {
      expect(VoteItemRequestServiceHelper.hasMoreResults(0, 20), isFalse);
    });

    test('returns false when resultCount exceeds pageSize (edge case)', () {
      // Shouldn't normally happen but should not claim "more"
      expect(VoteItemRequestServiceHelper.hasMoreResults(25, 20), isFalse);
    });
  });

  group('buildPaginationResult', () {
    test('returns correct map structure', () {
      final result = VoteItemRequestServiceHelper.buildPaginationResult(
        artists: ['a', 'b'],
        hasMore: true,
        currentPage: 2,
      );
      expect(result['artists'], equals(['a', 'b']));
      expect(result['hasMore'], isTrue);
      expect(result['currentPage'], equals(2));
    });
  });

  group('buildEmptyPaginationResult', () {
    test('returns empty artists list with hasMore false', () {
      final result = VoteItemRequestServiceHelper.buildEmptyPaginationResult(3);
      expect(result['artists'], isEmpty);
      expect(result['hasMore'], isFalse);
      expect(result['currentPage'], equals(3));
    });
  });

  // ===========================================================================
  // Batching
  // ===========================================================================
  group('splitIntoBatches', () {
    test('splits list evenly', () {
      final batches =
          VoteItemRequestServiceHelper.splitIntoBatches([1, 2, 3, 4], 2);
      expect(batches, [
        [1, 2],
        [3, 4],
      ]);
    });

    test('handles remainder', () {
      final batches =
          VoteItemRequestServiceHelper.splitIntoBatches([1, 2, 3, 4, 5], 2);
      expect(batches.length, 3);
      expect(batches[0], [1, 2]);
      expect(batches[1], [3, 4]);
      expect(batches[2], [5]);
    });

    test('handles empty list', () {
      final batches =
          VoteItemRequestServiceHelper.splitIntoBatches<int>([], 5);
      expect(batches, isEmpty);
    });

    test('handles batch size larger than list', () {
      final batches =
          VoteItemRequestServiceHelper.splitIntoBatches([1, 2], 10);
      expect(batches, [
        [1, 2],
      ]);
    });

    test('handles batch size of 1', () {
      final batches =
          VoteItemRequestServiceHelper.splitIntoBatches([1, 2, 3], 1);
      expect(batches.length, 3);
      expect(batches[0], [1]);
      expect(batches[1], [2]);
      expect(batches[2], [3]);
    });

    test('throws on zero batch size', () {
      expect(
        () => VoteItemRequestServiceHelper.splitIntoBatches([1], 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on negative batch size', () {
      expect(
        () => VoteItemRequestServiceHelper.splitIntoBatches([1], -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves data across enrichment batch boundaries', () {
      for (final itemCount in [0, 1, 50, 51, 100, 120]) {
        final items = List<int>.generate(itemCount, (index) => index);
        final batches = VoteItemRequestServiceHelper.splitIntoBatches(
          items,
          VoteItemRequestServiceHelper.enrichmentBatchSize,
        );

        expect(
          batches.every((batch) => batch.length <=
              VoteItemRequestServiceHelper.enrichmentBatchSize),
          isTrue,
          reason: 'itemCount: $itemCount',
        );
        expect(batches.expand((batch) => batch).toList(), items,
            reason: 'itemCount: $itemCount');
      }
    });
  });

  group('enrichment query bounds', () {
    test('keeps the enrichment batch size at 50', () {
      expect(VoteItemRequestServiceHelper.enrichmentBatchSize, 50);
    });

    test('returns deterministic signed-in query bounds', () {
      expect(_queryCount(0, true), 0);
      expect(_queryCount(1, true), 3);
      expect(_queryCount(50, true), 3);
      expect(_queryCount(51, true), 6);
      expect(_queryCount(100, true), 6);
      expect(_queryCount(120, true), 9);
    });

    test('returns deterministic anonymous query bounds', () {
      expect(_queryCount(0, false), 0);
      expect(_queryCount(50, false), 2);
      expect(_queryCount(51, false), 4);
      expect(_queryCount(100, false), 4);
    });

    test('rejects a negative artist count', () {
      expect(() => _queryCount(-1, true), throwsArgumentError);
    });
  });

  group('needsBatching', () {
    test('returns true when list exceeds max', () {
      expect(VoteItemRequestServiceHelper.needsBatching(51, 50), isTrue);
    });

    test('returns false when list equals max', () {
      expect(VoteItemRequestServiceHelper.needsBatching(50, 50), isFalse);
    });

    test('returns false when list is smaller', () {
      expect(VoteItemRequestServiceHelper.needsBatching(10, 50), isFalse);
    });
  });

  // ===========================================================================
  // Artist name extraction
  // ===========================================================================
  group('extractNames', () {
    test('extracts both names', () {
      final result = VoteItemRequestServiceHelper.extractNames(
          {'ko': '방탄소년단', 'en': 'BTS'});
      expect(result.ko, '방탄소년단');
      expect(result.en, 'BTS');
    });

    test('handles missing ko', () {
      final result =
          VoteItemRequestServiceHelper.extractNames({'en': 'BLACKPINK'});
      expect(result.ko, '');
      expect(result.en, 'BLACKPINK');
    });

    test('handles missing en', () {
      final result =
          VoteItemRequestServiceHelper.extractNames({'ko': '에스파'});
      expect(result.ko, '에스파');
      expect(result.en, '');
    });

    test('handles empty map', () {
      final result = VoteItemRequestServiceHelper.extractNames({});
      expect(result.ko, '');
      expect(result.en, '');
    });

    test('handles null values', () {
      final result = VoteItemRequestServiceHelper.extractNames(
          {'ko': null, 'en': null});
      expect(result.ko, '');
      expect(result.en, '');
    });
  });

  group('collectArtistNames', () {
    test('collects all non-empty names', () {
      final names = VoteItemRequestServiceHelper.collectArtistNames([
        {'ko': '방탄소년단', 'en': 'BTS'},
        {'ko': '에스파', 'en': 'aespa'},
      ]);
      expect(names, ['방탄소년단', 'BTS', '에스파', 'aespa']);
    });

    test('skips empty names', () {
      final names = VoteItemRequestServiceHelper.collectArtistNames([
        {'ko': '방탄소년단', 'en': ''},
        {'en': 'BLACKPINK'},
      ]);
      expect(names, ['방탄소년단', 'BLACKPINK']);
    });

    test('handles empty input', () {
      final names = VoteItemRequestServiceHelper.collectArtistNames([]);
      expect(names, isEmpty);
    });

    test('collectArtistNameSet removes duplicates and empty names', () {
      final names = VoteItemRequestServiceHelper.collectArtistNameSet([
        {'ko': 'BTS', 'en': 'BTS'},
        {'ko': '', 'en': 'aespa'},
        {'ko': 'BTS', 'en': ''},
      ]);
      expect(names, {'BTS', 'aespa'});
      expect(names, isA<Set<String>>());
    });
  });

  // ===========================================================================
  // Application count aggregation
  // ===========================================================================
  group('aggregateApplicationCount', () {
    final counts = {'방탄소년단': 5, 'BTS': 3, '에스파': 2};

    test('sums Korean and English counts', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        counts,
        '방탄소년단',
        'BTS',
      );
      expect(total, 8);
    });

    test('avoids double-counting when names are the same', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        {'SAME': 5},
        'SAME',
        'SAME',
      );
      expect(total, 5);
    });

    test('handles missing Korean name', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        counts,
        '',
        'BTS',
      );
      expect(total, 3);
    });

    test('handles missing English name', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        counts,
        '에스파',
        '',
      );
      expect(total, 2);
    });

    test('returns 0 for unknown names', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        counts,
        'unknown',
        'nope',
      );
      expect(total, 0);
    });

    test('returns 0 when both names are empty', () {
      final total = VoteItemRequestServiceHelper.aggregateApplicationCount(
        counts,
        '',
        '',
      );
      expect(total, 0);
    });
  });

  // ===========================================================================
  // "Already in vote" resolution
  // ===========================================================================
  group('resolveIsAlreadyInVote', () {
    final flags = {'방탄소년단': true, 'BTS': true};

    test('returns true when Korean name is found', () {
      expect(
        VoteItemRequestServiceHelper.resolveIsAlreadyInVote(
            flags, '방탄소년단', ''),
        isTrue,
      );
    });

    test('returns true when English name is found', () {
      expect(
        VoteItemRequestServiceHelper.resolveIsAlreadyInVote(flags, '', 'BTS'),
        isTrue,
      );
    });

    test('returns false when neither name is found', () {
      expect(
        VoteItemRequestServiceHelper.resolveIsAlreadyInVote(
            flags, '에스파', 'aespa'),
        isFalse,
      );
    });

    test('returns false when both names are empty', () {
      expect(
        VoteItemRequestServiceHelper.resolveIsAlreadyInVote(flags, '', ''),
        isFalse,
      );
    });

    test('returns false on empty map', () {
      expect(
        VoteItemRequestServiceHelper.resolveIsAlreadyInVote(
            {}, '방탄소년단', 'BTS'),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // Application status resolution
  // ===========================================================================
  group('resolveApplicationStatus', () {
    const defaultStatus = '신청 가능';
    final userStatuses = {
      '123': '대기중',
      '방탄소년단': '승인됨',
      'BTS': '거절됨',
    };

    test('returns default when userId is null', () {
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: userStatuses,
          artistId: '123',
          koreanName: '방탄소년단',
          englishName: 'BTS',
          userId: null,
          defaultStatus: defaultStatus,
        ),
        equals(defaultStatus),
      );
    });

    test('prefers artist ID match', () {
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: userStatuses,
          artistId: '123',
          koreanName: '방탄소년단',
          englishName: 'BTS',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals('대기중'),
      );
    });

    test('falls back to Korean name', () {
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: userStatuses,
          artistId: '999',
          koreanName: '방탄소년단',
          englishName: 'BTS',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals('승인됨'),
      );
    });

    test('falls back to English name', () {
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: userStatuses,
          artistId: '999',
          koreanName: '에스파',
          englishName: 'BTS',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals('거절됨'),
      );
    });

    test('returns default when nothing matches', () {
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: userStatuses,
          artistId: '999',
          koreanName: '에스파',
          englishName: 'aespa',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals(defaultStatus),
      );
    });

    test('skips empty Korean name in lookup', () {
      final statuses = {'': 'should-not-match', 'BTS': '거절됨'};
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: statuses,
          artistId: '999',
          koreanName: '',
          englishName: 'BTS',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals('거절됨'),
      );
    });

    test('skips empty English name in lookup', () {
      final statuses = {'방탄소년단': '승인됨', '': 'should-not-match'};
      expect(
        VoteItemRequestServiceHelper.resolveApplicationStatus(
          userStatuses: statuses,
          artistId: '999',
          koreanName: '방탄소년단',
          englishName: '',
          userId: 'user1',
          defaultStatus: defaultStatus,
        ),
        equals('승인됨'),
      );
    });
  });

  // ===========================================================================
  // Status text mapping
  // ===========================================================================
  group('getStatusDisplayText', () {
    final statusMap = {
      'pending': '대기중',
      'approved': '승인됨',
      'rejected': '거절됨',
      'in-progress': '진행중',
      'cancelled': '취소됨',
    };

    test('maps known statuses', () {
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'pending', statusMap, '기본'),
        '대기중',
      );
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'approved', statusMap, '기본'),
        '승인됨',
      );
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'rejected', statusMap, '기본'),
        '거절됨',
      );
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'in-progress', statusMap, '기본'),
        '진행중',
      );
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'cancelled', statusMap, '기본'),
        '취소됨',
      );
    });

    test('is case-insensitive', () {
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'PENDING', statusMap, '기본'),
        '대기중',
      );
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'Approved', statusMap, '기본'),
        '승인됨',
      );
    });

    test('returns default for unknown status', () {
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            'unknown', statusMap, '기본'),
        '기본',
      );
    });

    test('returns default for empty status', () {
      expect(
        VoteItemRequestServiceHelper.getStatusDisplayText(
            '', statusMap, '기본'),
        '기본',
      );
    });
  });

  // ===========================================================================
  // Status count calculation
  // ===========================================================================
  group('countStatuses', () {
    test('counts each status', () {
      final result = VoteItemRequestServiceHelper.countStatuses(
        ['pending', 'approved', 'pending', 'rejected', 'pending'],
      );
      expect(result, {'pending': 3, 'approved': 1, 'rejected': 1});
    });

    test('handles empty list', () {
      expect(VoteItemRequestServiceHelper.countStatuses([]), isEmpty);
    });

    test('handles single status', () {
      expect(
        VoteItemRequestServiceHelper.countStatuses(['approved']),
        {'approved': 1},
      );
    });
  });

  // ===========================================================================
  // Artist application summary building & sorting
  // ===========================================================================
  group('buildArtistApplicationSummary', () {
    test('builds correct summary map', () {
      final statusCounts = {'pending': 2, 'approved': 1};
      final requests = ['req1', 'req2', 'req3'];
      final summary =
          VoteItemRequestServiceHelper.buildArtistApplicationSummary(
        artistId: 42,
        artistJson: {'name': 'test'},
        totalApplications: 3,
        statusCounts: statusCounts,
        requests: requests,
      );

      expect(summary['artistId'], 42);
      expect(summary['artist'], {'name': 'test'});
      expect(summary['totalApplications'], 3);
      expect(summary['pendingCount'], 2);
      expect(summary['approvedCount'], 1);
      expect(summary['rejectedCount'], 0);
      expect(summary['statusCounts'], statusCounts);
      expect(summary['requests'], requests);
      expect(summary['latestRequest'], 'req1');
    });

    test('handles empty requests list', () {
      final summary =
          VoteItemRequestServiceHelper.buildArtistApplicationSummary(
        artistId: 1,
        artistJson: null,
        totalApplications: 0,
        statusCounts: {},
        requests: [],
      );
      expect(summary['latestRequest'], isNull);
      expect(summary['artist'], isNull);
      expect(summary['pendingCount'], 0);
      expect(summary['approvedCount'], 0);
      expect(summary['rejectedCount'], 0);
    });
  });

  group('sortSummariesByCount', () {
    test('sorts descending by totalApplications', () {
      final summaries = [
        {'totalApplications': 5, 'name': 'A'},
        {'totalApplications': 10, 'name': 'B'},
        {'totalApplications': 3, 'name': 'C'},
      ];
      final sorted =
          VoteItemRequestServiceHelper.sortSummariesByCount(summaries);
      expect(sorted[0]['name'], 'B');
      expect(sorted[1]['name'], 'A');
      expect(sorted[2]['name'], 'C');
    });

    test('does not mutate original list', () {
      final summaries = [
        {'totalApplications': 1, 'name': 'A'},
        {'totalApplications': 3, 'name': 'B'},
      ];
      VoteItemRequestServiceHelper.sortSummariesByCount(summaries);
      expect(summaries[0]['name'], 'A'); // Original unchanged
    });

    test('handles empty list', () {
      expect(VoteItemRequestServiceHelper.sortSummariesByCount([]), isEmpty);
    });

    test('handles single item', () {
      final summaries = [
        {'totalApplications': 5, 'name': 'A'}
      ];
      final sorted =
          VoteItemRequestServiceHelper.sortSummariesByCount(summaries);
      expect(sorted.length, 1);
      expect(sorted[0]['name'], 'A');
    });
  });

  // ===========================================================================
  // Empty / error result builders
  // ===========================================================================
  group('buildEmptyApplicationCountsResult', () {
    test('returns correct structure with empty collections', () {
      final result =
          VoteItemRequestServiceHelper.buildEmptyApplicationCountsResult();
      expect(result['userApplications'], isA<List>());
      expect((result['userApplications'] as List), isEmpty);
      expect(result['userApplicationsWithDetails'], isA<List>());
      expect(result['userApplicationCounts'], isA<Map>());
      expect((result['userApplicationCounts'] as Map), isEmpty);
    });
  });

  group('buildEmptyAllApplicationsResult', () {
    test('returns correct structure', () {
      final result =
          VoteItemRequestServiceHelper.buildEmptyAllApplicationsResult();
      expect(result['artistApplicationSummaries'], isA<List>());
      expect((result['artistApplicationSummaries'] as List), isEmpty);
      expect(result['totalApplications'], 0);
    });
  });

  group('buildDefaultApplicationInfo', () {
    test('returns info with zero count and not in vote', () {
      final info = VoteItemRequestServiceHelper.buildDefaultApplicationInfo(
        artistName: 'BTS',
        canApplyText: '신청 가능',
      );
      expect(info.artistName, 'BTS');
      expect(info.applicationCount, 0);
      expect(info.applicationStatus, '신청 가능');
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });
  });

  // ===========================================================================
  // Artist name matching
  // ===========================================================================
  group('findExactArtistMatch', () {
    final candidates = [
      {'displayName': '방탄소년단 (BTS)', 'ko': '방탄소년단', 'en': 'BTS'},
      {'displayName': '에스파 (aespa)', 'ko': '에스파', 'en': 'aespa'},
      {'displayName': 'BLACKPINK', 'ko': '', 'en': 'BLACKPINK'},
    ];

    test('matches by displayName', () {
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch(
            candidates, '에스파 (aespa)'),
        1,
      );
    });

    test('matches by Korean name', () {
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch(
            candidates, '방탄소년단'),
        0,
      );
    });

    test('matches by English name', () {
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch(
            candidates, 'BLACKPINK'),
        2,
      );
    });

    test('returns -1 when no match', () {
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch(
            candidates, 'TWICE'),
        -1,
      );
    });

    test('returns first match when multiple could match', () {
      final dupes = [
        {'displayName': 'A', 'ko': 'X', 'en': 'Y'},
        {'displayName': 'B', 'ko': 'X', 'en': 'Z'},
      ];
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch(dupes, 'X'),
        0,
      );
    });

    test('handles empty candidates', () {
      expect(
        VoteItemRequestServiceHelper.findExactArtistMatch([], 'BTS'),
        -1,
      );
    });
  });

  group('artistNameMatchesVoteItem', () {
    test('matches Korean name', () {
      expect(
        VoteItemRequestServiceHelper.artistNameMatchesVoteItem(
          artistName: '방탄소년단',
          koreanNameFromDb: '방탄소년단',
          englishNameFromDb: 'BTS',
          displayNameFromDb: '방탄소년단 (BTS)',
        ),
        isTrue,
      );
    });

    test('matches English name', () {
      expect(
        VoteItemRequestServiceHelper.artistNameMatchesVoteItem(
          artistName: 'BTS',
          koreanNameFromDb: '방탄소년단',
          englishNameFromDb: 'BTS',
          displayNameFromDb: '방탄소년단 (BTS)',
        ),
        isTrue,
      );
    });

    test('matches display name', () {
      expect(
        VoteItemRequestServiceHelper.artistNameMatchesVoteItem(
          artistName: '방탄소년단 (BTS)',
          koreanNameFromDb: '방탄소년단',
          englishNameFromDb: 'BTS',
          displayNameFromDb: '방탄소년단 (BTS)',
        ),
        isTrue,
      );
    });

    test('returns false for no match', () {
      expect(
        VoteItemRequestServiceHelper.artistNameMatchesVoteItem(
          artistName: 'TWICE',
          koreanNameFromDb: '방탄소년단',
          englishNameFromDb: 'BTS',
          displayNameFromDb: '방탄소년단 (BTS)',
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // Application count accumulation from response rows
  // ===========================================================================
  group('accumulateApplicationCounts', () {
    test('accumulates counts from response rows', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          }
        },
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          }
        },
        {
          'artist': {
            'name': {'ko': '에스파', 'en': 'aespa'}
          }
        },
      ];
      final relevant = ['방탄소년단', 'BTS', '에스파', 'aespa'];

      final counts = VoteItemRequestServiceHelper.accumulateApplicationCounts(
          rows, relevant);

      expect(counts['방탄소년단'], 2);
      expect(counts['BTS'], 2);
      expect(counts['에스파'], 1);
      expect(counts['aespa'], 1);
    });

    test('skips rows with null artist', () {
      final rows = [
        {'artist': null},
        {
          'artist': {
            'name': {'ko': '에스파', 'en': 'aespa'}
          }
        },
      ];
      final counts = VoteItemRequestServiceHelper.accumulateApplicationCounts(
          rows, ['에스파', 'aespa']);
      expect(counts['에스파'], 1);
    });

    test('skips names not in relevant list', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          }
        },
      ];
      final counts = VoteItemRequestServiceHelper.accumulateApplicationCounts(
          rows, ['에스파']);
      expect(counts, isEmpty);
    });

    test('handles empty rows', () {
      final counts =
          VoteItemRequestServiceHelper.accumulateApplicationCounts([], ['BTS']);
      expect(counts, isEmpty);
    });

    test('handles missing name data', () {
      final rows = [
        {
          'artist': {'name': null}
        },
      ];
      final counts = VoteItemRequestServiceHelper.accumulateApplicationCounts(
          rows, ['BTS']);
      expect(counts, isEmpty);
    });
  });

  group('extractAlreadyInVoteFlags', () {
    test('extracts flags for relevant names', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          }
        },
      ];
      final flags = VoteItemRequestServiceHelper.extractAlreadyInVoteFlags(
          rows, ['방탄소년단', 'BTS']);
      expect(flags['방탄소년단'], isTrue);
      expect(flags['BTS'], isTrue);
    });

    test('skips irrelevant names', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          }
        },
      ];
      final flags = VoteItemRequestServiceHelper.extractAlreadyInVoteFlags(
          rows, ['에스파']);
      expect(flags, isEmpty);
    });

    test('handles null artist', () {
      final rows = [
        {'artist': null},
      ];
      final flags = VoteItemRequestServiceHelper.extractAlreadyInVoteFlags(
          rows, ['BTS']);
      expect(flags, isEmpty);
    });
  });

  group('extractUserApplicationStatuses', () {
    String mockStatusText(String status) => 'display_$status';

    test('extracts statuses for relevant names and artist IDs', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          },
          'status': 'pending',
          'artist_id': 42,
        },
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['방탄소년단', 'BTS'], mockStatusText);

      expect(statuses['방탄소년단'], 'display_pending');
      expect(statuses['BTS'], 'display_pending');
      expect(statuses['42'], 'display_pending');
    });

    test('skips irrelevant names but still stores artist ID', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          },
          'status': 'approved',
          'artist_id': 10,
        },
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['에스파'], mockStatusText);

      expect(statuses.containsKey('방탄소년단'), isFalse);
      expect(statuses.containsKey('BTS'), isFalse);
      expect(statuses['10'], 'display_approved');
    });

    test('handles null artist', () {
      final rows = [
        {'artist': null, 'status': 'pending', 'artist_id': 1},
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['BTS'], mockStatusText);
      expect(statuses, isEmpty);
    });

    test('handles null artist_id', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          },
          'status': 'pending',
          'artist_id': null,
        },
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['방탄소년단'], mockStatusText);
      expect(statuses['방탄소년단'], 'display_pending');
      // null artist_id should be skipped (no 'null' key stored)
      expect(statuses.containsKey('null'), isFalse);
    });

    test('handles empty status', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': ''}
          },
          'status': '',
          'artist_id': 5,
        },
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['방탄소년단'], mockStatusText);
      expect(statuses['방탄소년단'], 'display_');
    });

    test('handles multiple rows', () {
      final rows = [
        {
          'artist': {
            'name': {'ko': '방탄소년단', 'en': 'BTS'}
          },
          'status': 'pending',
          'artist_id': 1,
        },
        {
          'artist': {
            'name': {'ko': '에스파', 'en': 'aespa'}
          },
          'status': 'approved',
          'artist_id': 2,
        },
      ];
      final statuses =
          VoteItemRequestServiceHelper.extractUserApplicationStatuses(
              rows, ['방탄소년단', 'BTS', '에스파', 'aespa'], mockStatusText);

      expect(statuses['방탄소년단'], 'display_pending');
      expect(statuses['BTS'], 'display_pending');
      expect(statuses['1'], 'display_pending');
      expect(statuses['에스파'], 'display_approved');
      expect(statuses['aespa'], 'display_approved');
      expect(statuses['2'], 'display_approved');
    });
  });
}
