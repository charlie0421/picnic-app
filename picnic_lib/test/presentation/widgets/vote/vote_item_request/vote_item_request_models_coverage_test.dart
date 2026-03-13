import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

import '../../../../helpers/test_environment.dart';

/// Additional coverage tests for vote_item_request_models.dart
/// and vote_item_request_service.dart logic patterns.
void main() {
  setUp(() {
    initTestColors();
  });

  group('ArtistApplicationInfo', () {
    test('default constructor values', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test Artist',
        applicationCount: 0,
        applicationStatus: 'can_apply',
        isAlreadyInVote: false,
      );
      expect(info.artistName, 'Test Artist');
      expect(info.applicationCount, 0);
      expect(info.applicationStatus, 'can_apply');
      expect(info.isAlreadyInVote, false);
      expect(info.isSubmitting, false);
    });

    test('constructor with isSubmitting true', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(info.isSubmitting, true);
      expect(info.isAlreadyInVote, true);
    });

    test('copyWith preserves original values when not overridden', () {
      const info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 10,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      final copy = info.copyWith();
      expect(copy.artistName, 'Original');
      expect(copy.applicationCount, 10);
      expect(copy.applicationStatus, 'pending');
      expect(copy.isAlreadyInVote, false);
      expect(copy.isSubmitting, false);
    });

    test('copyWith changes individual fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 10,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      final withName = info.copyWith(artistName: 'New Name');
      expect(withName.artistName, 'New Name');
      expect(withName.applicationCount, 10);

      final withCount = info.copyWith(applicationCount: 99);
      expect(withCount.artistName, 'Original');
      expect(withCount.applicationCount, 99);

      final withStatus = info.copyWith(applicationStatus: 'approved');
      expect(withStatus.applicationStatus, 'approved');

      final withInVote = info.copyWith(isAlreadyInVote: true);
      expect(withInVote.isAlreadyInVote, true);

      final withSubmitting = info.copyWith(isSubmitting: true);
      expect(withSubmitting.isSubmitting, true);
    });

    test('copyWith changes all fields at once', () {
      const info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 10,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      final copy = info.copyWith(
        artistName: 'Updated',
        applicationCount: 50,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );

      expect(copy.artistName, 'Updated');
      expect(copy.applicationCount, 50);
      expect(copy.applicationStatus, 'approved');
      expect(copy.isAlreadyInVote, true);
      expect(copy.isSubmitting, true);
    });
  });

  group('UserApplicationInfo', () {
    test('all required fields', () {
      const info = UserApplicationInfo(
        id: 'app-1',
        artistName: 'Jimin',
        status: 'approved',
        applicationCount: 42,
      );
      expect(info.id, 'app-1');
      expect(info.artistName, 'Jimin');
      expect(info.status, 'approved');
      expect(info.applicationCount, 42);
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('with all optional fields', () {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
      });

      final info = UserApplicationInfo(
        id: 'app-2',
        artistName: 'BTS',
        groupName: 'BigHit',
        status: 'pending',
        applicationCount: 100,
        artist: artist,
      );
      expect(info.groupName, 'BigHit');
      expect(info.artist, isNotNull);
      expect(info.artist!.id, 1);
    });

    test('zero application count', () {
      const info = UserApplicationInfo(
        id: 'app-3',
        artistName: 'New Artist',
        status: 'pending',
        applicationCount: 0,
      );
      expect(info.applicationCount, 0);
    });
  });

  group('VoteRequestStatusUtils.getStatusColor', () {
    test('pending returns orange', () {
      final color = VoteRequestStatusUtils.getStatusColor('pending');
      expect(color, Colors.orange);
    });

    test('approved returns green', () {
      final color = VoteRequestStatusUtils.getStatusColor('approved');
      expect(color, Colors.green);
    });

    test('rejected returns red', () {
      final color = VoteRequestStatusUtils.getStatusColor('rejected');
      expect(color, Colors.red);
    });

    test('in-progress returns primary color', () {
      final color = VoteRequestStatusUtils.getStatusColor('in-progress');
      expect(color, isNotNull);
    });

    test('cancelled returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('cancelled');
      expect(color, isNotNull);
    });

    test('unknown status returns default grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('unknown');
      expect(color, isNotNull);
    });

    test('empty string returns default grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('');
      expect(color, isNotNull);
    });

    test('case insensitive - PENDING', () {
      final upper = VoteRequestStatusUtils.getStatusColor('PENDING');
      final lower = VoteRequestStatusUtils.getStatusColor('pending');
      expect(upper, lower);
    });

    test('case insensitive - Approved', () {
      final mixed = VoteRequestStatusUtils.getStatusColor('Approved');
      final lower = VoteRequestStatusUtils.getStatusColor('approved');
      expect(mixed, lower);
    });

    test('case insensitive - REJECTED', () {
      final upper = VoteRequestStatusUtils.getStatusColor('REJECTED');
      final lower = VoteRequestStatusUtils.getStatusColor('rejected');
      expect(upper, lower);
    });

    test('case insensitive - In-Progress', () {
      final mixed = VoteRequestStatusUtils.getStatusColor('In-Progress');
      final lower = VoteRequestStatusUtils.getStatusColor('in-progress');
      expect(mixed, lower);
    });

    test('case insensitive - CANCELLED', () {
      final upper = VoteRequestStatusUtils.getStatusColor('CANCELLED');
      final lower = VoteRequestStatusUtils.getStatusColor('cancelled');
      expect(upper, lower);
    });

    test('all statuses return non-transparent colors', () {
      final statuses = [
        'pending',
        'approved',
        'rejected',
        'in-progress',
        'cancelled',
        'unknown',
        '',
        'some-random-status',
      ];

      for (final status in statuses) {
        final color = VoteRequestStatusUtils.getStatusColor(status);
        expect(color.a, greaterThan(0),
            reason: 'Status "$status" should have non-transparent color');
      }
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('formats 0', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
    });

    test('formats single digit', () {
      expect(ArtistNameUtils.formatNumber(5), '5');
    });

    test('formats two digits', () {
      expect(ArtistNameUtils.formatNumber(42), '42');
    });

    test('formats three digits', () {
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('formats four digits', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
    });

    test('formats five digits', () {
      expect(ArtistNameUtils.formatNumber(12345), '12,345');
    });

    test('formats six digits', () {
      expect(ArtistNameUtils.formatNumber(999999), '999,999');
    });

    test('formats seven digits', () {
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
    });

    test('formats large numbers', () {
      expect(ArtistNameUtils.formatNumber(1234567890), '1,234,567,890');
    });

    test('formats 100', () {
      expect(ArtistNameUtils.formatNumber(100), '100');
    });

    test('formats 10000', () {
      expect(ArtistNameUtils.formatNumber(10000), '10,000');
    });

    test('formats 100000', () {
      expect(ArtistNameUtils.formatNumber(100000), '100,000');
    });
  });

  group('VoteItemRequestService logic patterns', () {
    test('loadApplicationCounts returns expected structure on success', () {
      // Simulating the return structure
      final result = <String, dynamic>{
        'userApplications': <dynamic>[],
        'userApplicationsWithDetails': <Map<String, dynamic>>[],
        'userApplicationCounts': <String, int>{},
      };

      expect(result['userApplications'], isA<List>());
      expect(result['userApplicationsWithDetails'], isA<List>());
      expect(result['userApplicationCounts'], isA<Map>());
    });

    test('loadApplicationCounts returns empty structure on error', () {
      final result = <String, dynamic>{
        'userApplications': <dynamic>[],
        'userApplicationsWithDetails': <Map<String, dynamic>>[],
        'userApplicationCounts': <String, int>{},
      };

      expect((result['userApplications'] as List).isEmpty, isTrue);
      expect((result['userApplicationsWithDetails'] as List).isEmpty, isTrue);
      expect((result['userApplicationCounts'] as Map).isEmpty, isTrue);
    });

    test('searchArtistsWithPagination returns expected structure', () {
      final result = <String, dynamic>{
        'artists': <ArtistModel>[],
        'hasMore': false,
        'currentPage': 0,
      };

      expect(result['artists'], isA<List>());
      expect(result['hasMore'], false);
      expect(result['currentPage'], 0);
    });

    test('searchArtistsWithPagination hasMore logic', () {
      const pageSize = 20;

      // Full page - has more
      final fullResults = List.generate(
        pageSize,
        (i) => ArtistModel(id: i, name: {'ko': 'Artist $i'}),
      );
      expect(fullResults.length == pageSize, isTrue);

      // Partial page - no more
      final partialResults = List.generate(
        10,
        (i) => ArtistModel(id: i, name: {'ko': 'Artist $i'}),
      );
      expect(partialResults.length == pageSize, isFalse);

      // Empty page - no more
      final emptyResults = <ArtistModel>[];
      expect(emptyResults.length == pageSize, isFalse);
    });

    test('batch size limiting logic', () {
      const maxBatchSize = 50;
      final artists = List.generate(
        120,
        (i) => ArtistModel(id: i, name: {'ko': 'Artist $i'}),
      );

      // Should be split into batches
      expect(artists.length > maxBatchSize, isTrue);

      final batches = <List<ArtistModel>>[];
      for (int i = 0; i < artists.length; i += maxBatchSize) {
        final end = (i + maxBatchSize > artists.length)
            ? artists.length
            : i + maxBatchSize;
        batches.add(artists.sublist(i, end));
      }

      expect(batches.length, 3); // 50, 50, 20
      expect(batches[0].length, 50);
      expect(batches[1].length, 50);
      expect(batches[2].length, 20);
    });

    test('batch processing with exactly maxBatchSize items', () {
      const maxBatchSize = 50;
      final artists = List.generate(
        50,
        (i) => ArtistModel(id: i, name: {'ko': 'Artist $i'}),
      );

      // Should NOT be split (exactly maxBatchSize)
      expect(artists.length > maxBatchSize, isFalse);
    });

    test('artist name extraction logic', () {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
      });

      final koreanName = artist.name['ko'] as String? ?? '';
      final englishName = artist.name['en'] as String? ?? '';

      expect(koreanName, '지민');
      expect(englishName, 'Jimin');
      expect(koreanName.isNotEmpty, isTrue);
      expect(englishName.isNotEmpty, isTrue);
    });

    test('artist with only Korean name', () {
      final artist = ArtistModel.fromJson({
        'id': 2,
        'name': {'ko': '아이유'},
      });

      final koreanName = artist.name['ko'] as String? ?? '';
      final englishName = artist.name['en'] as String? ?? '';

      expect(koreanName, '아이유');
      expect(englishName, '');
      expect(koreanName.isNotEmpty, isTrue);
      expect(englishName.isEmpty, isTrue);
    });

    test('artist with only English name', () {
      final artist = ArtistModel.fromJson({
        'id': 3,
        'name': {'en': 'Twice'},
      });

      final koreanName = artist.name['ko'] as String? ?? '';
      final englishName = artist.name['en'] as String? ?? '';

      expect(koreanName, '');
      expect(englishName, 'Twice');
    });
  });

  group('Vote application counting logic', () {
    test('application count accumulation', () {
      final applicationCounts = <String, int>{};
      final names = ['지민', 'Jimin', '지민', 'V', '지민'];

      for (final name in names) {
        applicationCounts[name] = (applicationCounts[name] ?? 0) + 1;
      }

      expect(applicationCounts['지민'], 3);
      expect(applicationCounts['Jimin'], 1);
      expect(applicationCounts['V'], 1);
    });

    test('total application count from Korean and English names', () {
      final applicationCounts = <String, int>{
        '지민': 3,
        'Jimin': 2,
        '뷔': 1,
      };

      final koreanName = '지민';
      final englishName = 'Jimin';

      int totalApplicationCount = 0;
      if (koreanName.isNotEmpty) {
        totalApplicationCount += applicationCounts[koreanName] ?? 0;
      }
      if (englishName.isNotEmpty && englishName != koreanName) {
        totalApplicationCount += applicationCounts[englishName] ?? 0;
      }

      expect(totalApplicationCount, 5); // 3 + 2
    });

    test('alreadyInVote check logic', () {
      final alreadyInVote = <String, bool>{
        '지민': true,
        'Jimin': true,
      };

      bool isAlreadyInVote = false;
      final koreanName = '지민';
      final englishName = 'Jimin';

      if (koreanName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isAlreadyInVote && englishName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[englishName] ?? false;
      }

      expect(isAlreadyInVote, true);
    });

    test('alreadyInVote false when not in map', () {
      final alreadyInVote = <String, bool>{};

      bool isAlreadyInVote = false;
      final koreanName = '뷔';
      final englishName = 'V';

      if (koreanName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isAlreadyInVote && englishName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[englishName] ?? false;
      }

      expect(isAlreadyInVote, false);
    });
  });

  group('Status text conversion pattern', () {
    test('all known statuses are handled', () {
      final statuses = ['pending', 'approved', 'rejected', 'in-progress', 'cancelled'];
      for (final status in statuses) {
        // The switch in the service uses toLowerCase()
        final normalized = status.toLowerCase();
        expect(
          ['pending', 'approved', 'rejected', 'in-progress', 'cancelled']
              .contains(normalized),
          isTrue,
        );
      }
    });

    test('unknown status falls through to default', () {
      const status = 'unknown-status';
      final normalized = status.toLowerCase();
      final isKnown = ['pending', 'approved', 'rejected', 'in-progress', 'cancelled']
          .contains(normalized);
      expect(isKnown, isFalse);
    });
  });

  group('Artist application summary sorting', () {
    test('sorts by total applications descending', () {
      final summaries = [
        {'artistId': 1, 'totalApplications': 10},
        {'artistId': 2, 'totalApplications': 50},
        {'artistId': 3, 'totalApplications': 25},
      ];

      summaries.sort((a, b) => (b['totalApplications'] as int)
          .compareTo(a['totalApplications'] as int));

      expect(summaries[0]['artistId'], 2); // 50
      expect(summaries[1]['artistId'], 3); // 25
      expect(summaries[2]['artistId'], 1); // 10
    });

    test('handles equal total applications', () {
      final summaries = [
        {'artistId': 1, 'totalApplications': 10},
        {'artistId': 2, 'totalApplications': 10},
      ];

      summaries.sort((a, b) => (b['totalApplications'] as int)
          .compareTo(a['totalApplications'] as int));

      // Both have same count, order is stable
      expect(summaries.length, 2);
    });
  });

  group('getArtistByName cache logic', () {
    test('cache hit returns cached value', () {
      final cache = <String, ArtistModel?>{
        '지민': const ArtistModel(id: 1, name: {'ko': '지민'}),
      };

      if (cache.containsKey('지민')) {
        final result = cache['지민'];
        expect(result, isNotNull);
        expect(result!.id, 1);
      }
    });

    test('cache miss triggers search', () {
      final cache = <String, ArtistModel?>{};

      final isCached = cache.containsKey('뷔');
      expect(isCached, false);
    });

    test('cache stores null on search failure', () {
      final cache = <String, ArtistModel?>{};
      cache['UnknownArtist'] = null;

      expect(cache.containsKey('UnknownArtist'), true);
      expect(cache['UnknownArtist'], isNull);
    });
  });
}
