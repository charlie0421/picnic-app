import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

/// Coverage-focused tests for VoteItemRequestService logic patterns.
///
/// VoteItemRequestService cannot be instantiated in tests because it requires:
/// - WidgetRef
/// - Supabase.instance.client
/// - SearchService (Supabase-backed)
/// - VoteItemRequestRepository (Supabase-backed)
/// - navigatorKey.currentContext for localization
///
/// Instead we test the logic patterns and data structures used within.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Application status text logic (mirrors _getUserApplicationStatusText)',
      () {
    String getUserStatusCategory(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return 'pending';
        case 'approved':
          return 'approved';
        case 'rejected':
          return 'rejected';
        case 'in-progress':
          return 'in-progress';
        case 'cancelled':
          return 'cancelled';
        default:
          return 'can_apply';
      }
    }

    test('pending status', () {
      expect(getUserStatusCategory('pending'), 'pending');
    });

    test('approved status', () {
      expect(getUserStatusCategory('approved'), 'approved');
    });

    test('rejected status', () {
      expect(getUserStatusCategory('rejected'), 'rejected');
    });

    test('in-progress status', () {
      expect(getUserStatusCategory('in-progress'), 'in-progress');
    });

    test('cancelled status', () {
      expect(getUserStatusCategory('cancelled'), 'cancelled');
    });

    test('unknown status defaults to can_apply', () {
      expect(getUserStatusCategory('unknown'), 'can_apply');
    });

    test('empty status defaults to can_apply', () {
      expect(getUserStatusCategory(''), 'can_apply');
    });

    test('case insensitive - PENDING', () {
      expect(getUserStatusCategory('PENDING'), 'pending');
    });

    test('case insensitive - Approved', () {
      expect(getUserStatusCategory('Approved'), 'approved');
    });
  });

  group('Artist name extraction logic (mirrors _loadApplicationDataBatch)', () {
    test('extracts Korean and English names', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      final koreanName = nameMap['ko'] as String? ?? '';
      final englishName = nameMap['en'] as String? ?? '';

      expect(koreanName, '방탄소년단');
      expect(englishName, 'BTS');
    });

    test('handles missing Korean name', () {
      final nameMap = {'en': 'BTS'};
      final koreanName = nameMap['ko'] as String? ?? '';
      expect(koreanName, '');
    });

    test('handles missing English name', () {
      final nameMap = {'ko': '방탄소년단'};
      final englishName = nameMap['en'] as String? ?? '';
      expect(englishName, '');
    });

    test('handles empty name map', () {
      final nameMap = <String, dynamic>{};
      final koreanName = nameMap['ko'] as String? ?? '';
      final englishName = nameMap['en'] as String? ?? '';
      expect(koreanName, '');
      expect(englishName, '');
    });
  });

  group('Application count calculation logic', () {
    test('counts applications from Korean name', () {
      final applicationCounts = {'방탄소년단': 5, 'BTS': 3};
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      int total = 0;
      if (koreanName.isNotEmpty) {
        total += applicationCounts[koreanName] ?? 0;
      }
      if (englishName.isNotEmpty && englishName != koreanName) {
        total += applicationCounts[englishName] ?? 0;
      }

      expect(total, 8);
    });

    test('avoids double counting when names are same', () {
      final applicationCounts = {'SameName': 5};
      const koreanName = 'SameName';
      const englishName = 'SameName';

      int total = 0;
      if (koreanName.isNotEmpty) {
        total += applicationCounts[koreanName] ?? 0;
      }
      if (englishName.isNotEmpty && englishName != koreanName) {
        total += applicationCounts[englishName] ?? 0;
      }

      expect(total, 5); // Not 10 because englishName == koreanName
    });

    test('handles no applications', () {
      final applicationCounts = <String, int>{};
      const koreanName = '방탄소년단';

      int total = 0;
      if (koreanName.isNotEmpty) {
        total += applicationCounts[koreanName] ?? 0;
      }

      expect(total, 0);
    });
  });

  group('Already in vote detection logic', () {
    test('detects by Korean name', () {
      final alreadyInVote = {'방탄소년단': true};
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      bool isInVote = false;
      if (koreanName.isNotEmpty) {
        isInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isInVote && englishName.isNotEmpty) {
        isInVote = alreadyInVote[englishName] ?? false;
      }

      expect(isInVote, isTrue);
    });

    test('detects by English name', () {
      final alreadyInVote = {'BTS': true};
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      bool isInVote = false;
      if (koreanName.isNotEmpty) {
        isInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isInVote && englishName.isNotEmpty) {
        isInVote = alreadyInVote[englishName] ?? false;
      }

      expect(isInVote, isTrue);
    });

    test('not in vote when no match', () {
      final alreadyInVote = {'Other': true};
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      bool isInVote = false;
      if (koreanName.isNotEmpty) {
        isInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isInVote && englishName.isNotEmpty) {
        isInVote = alreadyInVote[englishName] ?? false;
      }

      expect(isInVote, isFalse);
    });
  });

  group('User application status priority logic', () {
    test('artist ID has highest priority', () {
      final statuses = {'42': 'pending', '방탄소년단': 'approved', 'BTS': 'rejected'};
      const artistId = '42';
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      String status = 'can_apply';
      if (statuses.containsKey(artistId)) {
        status = statuses[artistId]!;
      } else if (koreanName.isNotEmpty && statuses.containsKey(koreanName)) {
        status = statuses[koreanName]!;
      } else if (englishName.isNotEmpty && statuses.containsKey(englishName)) {
        status = statuses[englishName]!;
      }

      expect(status, 'pending'); // ID match takes priority
    });

    test('Korean name is second priority', () {
      final statuses = {'방탄소년단': 'approved', 'BTS': 'rejected'};
      const artistId = '999';
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      String status = 'can_apply';
      if (statuses.containsKey(artistId)) {
        status = statuses[artistId]!;
      } else if (koreanName.isNotEmpty && statuses.containsKey(koreanName)) {
        status = statuses[koreanName]!;
      } else if (englishName.isNotEmpty && statuses.containsKey(englishName)) {
        status = statuses[englishName]!;
      }

      expect(status, 'approved'); // Korean name match
    });

    test('English name is third priority', () {
      final statuses = {'BTS': 'rejected'};
      const artistId = '999';
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      String status = 'can_apply';
      if (statuses.containsKey(artistId)) {
        status = statuses[artistId]!;
      } else if (koreanName.isNotEmpty && statuses.containsKey(koreanName)) {
        status = statuses[koreanName]!;
      } else if (englishName.isNotEmpty && statuses.containsKey(englishName)) {
        status = statuses[englishName]!;
      }

      expect(status, 'rejected'); // English name match
    });

    test('defaults to can_apply when no match', () {
      final statuses = <String, String>{};
      const artistId = '999';
      const koreanName = '방탄소년단';
      const englishName = 'BTS';

      String status = 'can_apply';
      if (statuses.containsKey(artistId)) {
        status = statuses[artistId]!;
      } else if (koreanName.isNotEmpty && statuses.containsKey(koreanName)) {
        status = statuses[koreanName]!;
      } else if (englishName.isNotEmpty && statuses.containsKey(englishName)) {
        status = statuses[englishName]!;
      }

      expect(status, 'can_apply');
    });
  });

  group('Batch processing logic', () {
    test('splits large list into batches of maxBatchSize', () {
      const maxBatchSize = 50;
      final items = List.generate(120, (i) => i);

      final batches = <List<int>>[];
      for (int i = 0; i < items.length; i += maxBatchSize) {
        final end =
            (i + maxBatchSize > items.length) ? items.length : i + maxBatchSize;
        batches.add(items.sublist(i, end));
      }

      expect(batches.length, 3);
      expect(batches[0].length, 50);
      expect(batches[1].length, 50);
      expect(batches[2].length, 20);
    });

    test('small list does not need batching', () {
      const maxBatchSize = 50;
      final items = List.generate(30, (i) => i);
      expect(items.length <= maxBatchSize, isTrue);
    });

    test('exactly maxBatchSize does not need batching', () {
      const maxBatchSize = 50;
      final items = List.generate(50, (i) => i);
      expect(items.length <= maxBatchSize, isTrue);
    });
  });

  group('Artist application summary sorting', () {
    test('sorts by total applications descending', () {
      final summaries = [
        {'artistId': 1, 'totalApplications': 5},
        {'artistId': 2, 'totalApplications': 15},
        {'artistId': 3, 'totalApplications': 8},
      ];

      summaries.sort((a, b) => (b['totalApplications'] as int)
          .compareTo(a['totalApplications'] as int));

      expect(summaries[0]['artistId'], 2);
      expect(summaries[1]['artistId'], 3);
      expect(summaries[2]['artistId'], 1);
    });

    test('equal totals maintain stable order', () {
      final summaries = [
        {'artistId': 1, 'totalApplications': 5},
        {'artistId': 2, 'totalApplications': 5},
      ];

      summaries.sort((a, b) => (b['totalApplications'] as int)
          .compareTo(a['totalApplications'] as int));

      // Dart's sort is stable, so equal elements maintain original order
      expect(summaries[0]['artistId'], 1);
      expect(summaries[1]['artistId'], 2);
    });
  });

  group('Pagination hasMore logic', () {
    test('full page means hasMore', () {
      const pageSize = 20;
      final results = List.generate(20, (i) => i);
      expect(results.length == pageSize, isTrue); // hasMore = true
    });

    test('partial page means no more', () {
      const pageSize = 20;
      final results = List.generate(15, (i) => i);
      expect(results.length == pageSize, isFalse); // hasMore = false
    });

    test('empty results means no more', () {
      const pageSize = 20;
      final results = <int>[];
      expect(results.length == pageSize, isFalse); // hasMore = false
    });
  });

  group('Artist display name logic (mirrors ArtistNameUtils.getDisplayName)',
      () {
    // ArtistNameUtils.getDisplayName requires navigatorKey.currentContext
    // which is not available in unit tests. We test the name extraction logic.
    String getDisplayName(Map<String, dynamic> nameMap) {
      final ko = nameMap['ko'] as String? ?? '';
      final en = nameMap['en'] as String? ?? '';
      if (ko.isNotEmpty && en.isNotEmpty) {
        return '$ko ($en)';
      } else if (ko.isNotEmpty) {
        return ko;
      } else if (en.isNotEmpty) {
        return en;
      }
      return '';
    }

    test('with both languages', () {
      final name = {'ko': '지민', 'en': 'Jimin'};
      expect(getDisplayName(name), '지민 (Jimin)');
    });

    test('with Korean only', () {
      final name = {'ko': '지민'};
      expect(getDisplayName(name), '지민');
    });

    test('with English only', () {
      final name = {'en': 'Jimin'};
      expect(getDisplayName(name), 'Jimin');
    });

    test('with empty map', () {
      final name = <String, dynamic>{};
      expect(getDisplayName(name), '');
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('formats large numbers', () {
      expect(ArtistNameUtils.formatNumber(1000), isNotEmpty);
      expect(ArtistNameUtils.formatNumber(0), isNotEmpty);
    });

    test('formats zero', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
    });
  });

  group('ArtistApplicationInfo', () {
    test('creates with all fields', () {
      final info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 42,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, 'BTS');
      expect(info.applicationCount, 42);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, isFalse);
    });

    test('copyWith changes specific fields', () {
      final info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 0,
        applicationStatus: 'can_apply',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(applicationCount: 10);
      expect(updated.applicationCount, 10);
      expect(updated.artistName, 'BTS'); // unchanged
    });
  });
}
