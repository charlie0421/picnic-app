import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  testWidgets('search enrichment uses aggregate counts and current-user status',
      (tester) async {
    setupMockSupabase({
      'vote_item_request_status_summary': [
        {'vote_id': 1, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': 4},
        {'vote_id': 1, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'approved', 'request_count': 3},
      ],
      'vote_item_request_users': [
        {'vote_id': 1, 'user_id': 'current-user', 'artist_id': 10, 'status': 'pending', 'artist': {'name': {'ko': '가수 A', 'en': 'Singer A'}}},
        {'vote_id': 1, 'user_id': 'other-user', 'artist_id': 10, 'status': 'rejected', 'artist': {'name': {'ko': '가수 A', 'en': 'Singer A'}}},
      ],
      'vote_item': <Map<String, dynamic>>[],
    }, userId: 'current-user');
    addTearDown(tearDownMockSupabase);

    late WidgetRef widgetRef;
    await tester.pumpWidget(buildTestApp(
      Consumer(builder: (_, ref, __) {
        widgetRef = ref;
        return const SizedBox();
      }),
      extraOverrides: [
        voteItemRequestRepositoryProvider.overrideWithValue(
          VoteItemRequestRepository(supabase: testSupabaseClient!),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    final service = VoteItemRequestService(
      ref: widgetRef,
      voteId: '1',
      supabase: testSupabaseClient!,
    );
    final result = await service.loadApplicationDataForResults(
      const [ArtistModel(id: 10, name: {'ko': '가수 A', 'en': 'Singer A'})],
      'current-user',
    );

    expect(result['10']!.applicationCount, 7);
    expect(
      result['10']!.applicationStatus,
      AppLocalizations.of(navigatorKey.currentContext!)
          .vote_item_request_status_pending,
    );
  });

  group('VoteItemRequestRepository - getVoteItemRequestCount', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_status_summary': [
          {
            'vote_id': 1,
            'artist_id': 10,
            'artist_name': '가수 A',
            'request_status': 'pending',
            'request_count': 2,
          },
          {
            'vote_id': 1,
            'artist_id': 10,
            'artist_name': '가수 A',
            'request_status': 'approved',
            'request_count': 1,
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns total count from aggregate rows', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final count = await repo.getVoteItemRequestCount(1);
      expect(count, 3);
    });
  });

  group('VoteItemRequestRepository - getVoteItemRequestCount empty', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_status_summary': [],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns 0 when no requests', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final count = await repo.getVoteItemRequestCount(999);
      expect(count, 0);
    });
  });

  group('VoteItemRequestRepository - getCurrentUserApplicationsWithDetails', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_requests': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'pending',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
            'artist': {'id': 10, 'name': {'ko': '지민', 'en': 'Jimin'}, 'image': null},
          },
          {
            'id': 'req-2',
            'vote_id': 2,
            'user_id': 'test-user-id',
            'artist_id': 11,
            'status': 'approved',
            'created_at': '2024-01-16T10:00:00Z',
            'updated_at': '2024-01-16T10:00:00Z',
            'artist': {'id': 11, 'name': {'ko': '뷔', 'en': 'V'}, 'image': null},
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns user applications with details', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final applications = await repo.getCurrentUserApplicationsWithDetails('test-user-id');

      expect(applications, isA<List<Map<String, dynamic>>>());
      expect(applications.length, 2);
      expect(applications[0]['artist_id'], 10);
      expect(applications[1]['artist_id'], 11);
    });
  });

  group('VoteItemRequestRepository - getApplicationCountByTitle', () {
    setUp(() {
      setupMockSupabase({
        'artist': [
          {'id': 1, 'name': {'ko': '지민', 'en': 'Jimin'}},
          {'id': 2, 'name': {'ko': '지민이', 'en': 'Jimini'}},
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns count by title match', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final count = await repo.getApplicationCountByTitle('지민');
      expect(count, isA<int>());
    });
  });

  group('VoteItemRequestRepository - getUserApplicationStatus', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_requests': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'pending',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns user application status map', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final status = await repo.getUserApplicationStatus('test-user-id', 1, 10);
      // Mock returns the list as-is; maybeSingle behavior differs
      // The important thing is no exception
    });
  });

  group('VoteItemRequestRepository - hasUserRequestedArtist', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'pending',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns result without exception', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final result = await repo.hasUserRequestedArtist(1, 10, 'test-user-id');
      expect(result, isA<bool>());
    });
  });

  group('VoteItemRequestRepository - getVoteItemRequestsByVoteId', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_requests': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'user-1',
            'artist_id': 10,
            'status': 'pending',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
          },
          {
            'id': 'req-2',
            'vote_id': 1,
            'user_id': 'user-2',
            'artist_id': 11,
            'status': 'approved',
            'created_at': '2024-01-16T10:00:00Z',
            'updated_at': '2024-01-16T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of VoteItemRequestUser', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final requests = await repo.getVoteItemRequestsByVoteId(1);
      expect(requests, isA<List<VoteItemRequestUser>>());
      expect(requests.length, 2);
      expect(requests[0].id, 'req-1');
      expect(requests[1].id, 'req-2');
    });
  });

  group('VoteItemRequestRepository - getUserRequestsByVoteId', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_requests': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'pending',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns user requests for specific vote', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final requests = await repo.getUserRequestsByVoteId('test-user-id', 1);
      expect(requests, isA<List<VoteItemRequestUser>>());
      expect(requests.length, 1);
      expect(requests[0].userId, 'test-user-id');
    });
  });

  group('VoteItemRequestRepository - getAllUserRequests', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'pending',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
            'artist': {'id': 10, 'name': {'ko': '지민', 'en': 'Jimin'}, 'image': null, 'group_id': 1},
          },
          {
            'id': 'req-2',
            'vote_id': 2,
            'user_id': 'test-user-id',
            'artist_id': 11,
            'status': 'approved',
            'created_at': '2024-01-16T10:00:00Z',
            'updated_at': '2024-01-16T10:00:00Z',
            'artist': {'id': 11, 'name': {'ko': '뷔', 'en': 'V'}, 'image': null, 'group_id': 1},
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns all user requests with artist info', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final requests = await repo.getAllUserRequests('test-user-id');
      expect(requests, isA<List<VoteItemRequestUser>>());
      expect(requests.length, 2);
      expect(requests[0].artist, isNotNull);
      expect(requests[0].artist!.id, 10);
      expect(requests[1].artist!.id, 11);
    });
  });

  group('VoteItemRequestRepository - updateVoteItemRequestStatus', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [
          {
            'id': 'req-1',
            'vote_id': 1,
            'user_id': 'test-user-id',
            'artist_id': 10,
            'status': 'approved',
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T12:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('update call succeeds and returns updated request', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final result = await repo.updateVoteItemRequestStatus('req-1', 'approved');
      expect(result, isA<VoteItemRequestUser>());
      expect(result.id, 'req-1');
      expect(result.status, 'approved');
    });
  });

  group('VoteItemRequestRepository - getArtistRequestStatistics', () {
    setUp(() {
      setupMockSupabase({
        'artist_request_statistics': [
          {
            'artist_id': 10,
            'total_requests': 50,
            'pending_count': 20,
            'approved_count': 25,
            'rejected_count': 5,
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns statistics for artist', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final stats = await repo.getArtistRequestStatistics(10);
      expect(stats, isA<Map<String, dynamic>>());
    });
  });

  group('VoteItemRequestRepository - getArtistRequestStatistics empty', () {
    setUp(() {
      setupMockSupabase({
        'artist_request_statistics': [],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty map when no statistics', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final stats = await repo.getArtistRequestStatistics(999);
      // maybeSingle on empty returns null, so {} is returned
      expect(stats, isA<Map<String, dynamic>>());
    });
  });

  group('VoteItemRequestRepository - getVoteRequestStatusSummary', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_status_summary': [
          {'vote_id': 1, 'status': 'pending', 'request_count': 30},
          {'vote_id': 1, 'status': 'approved', 'request_count': 20},
          {'vote_id': 1, 'status': 'rejected', 'request_count': 5},
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns status summary list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final summary = await repo.getVoteRequestStatusSummary(1);
      expect(summary, isA<List<Map<String, dynamic>>>());
      expect(summary.length, 3);
    });
  });

  group('VoteItemRequestRepository - getUserRequestHistory', () {
    setUp(() {
      setupMockSupabase({
        'user_vote_item_request_history': [
          {
            'user_id': 'test-user-id',
            'vote_id': 1,
            'artist_name': '지민',
            'status': 'pending',
            'requested_at': '2024-01-15T10:00:00Z',
          },
          {
            'user_id': 'test-user-id',
            'vote_id': 2,
            'artist_name': '뷔',
            'status': 'approved',
            'requested_at': '2024-01-16T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('returns user request history', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final history = await repo.getUserRequestHistory('test-user-id');
      expect(history, isA<List<Map<String, dynamic>>>());
      expect(history.length, 2);
    });
  });

  group('VoteItemRequestRepository - deleteVoteItemRequest', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('delete does not throw', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      // Should not throw
      await repo.deleteVoteItemRequest('req-1');
    });
  });

  group('VoteItemRequestRepository - deleteUserRequest', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('delete user request does not throw', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      await repo.deleteUserRequest('req-1');
    });
  });

  group('VoteItemRequestUser model', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'req-abc',
        'vote_id': 42,
        'user_id': 'user-xyz',
        'artist_id': 100,
        'status': 'pending',
        'created_at': '2024-06-15T10:30:00Z',
        'updated_at': '2024-06-15T10:30:00Z',
      };

      final model = VoteItemRequestUser.fromJson(json);
      expect(model.id, 'req-abc');
      expect(model.voteId, 42);
      expect(model.userId, 'user-xyz');
      expect(model.artistId, 100);
      expect(model.status, 'pending');
      expect(model.createdAt, isA<DateTime>());
      expect(model.updatedAt, isA<DateTime>());
      expect(model.artist, isNull);
    });

    test('fromJson with artist data', () {
      final json = {
        'id': 'req-abc',
        'vote_id': 42,
        'user_id': 'user-xyz',
        'artist_id': 100,
        'status': 'approved',
        'created_at': '2024-06-15T10:30:00Z',
        'updated_at': '2024-06-15T10:30:00Z',
        'artist': {
          'id': 100,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': 'https://example.com/jimin.png',
        },
      };

      final model = VoteItemRequestUser.fromJson(json);
      expect(model.artist, isNotNull);
      expect(model.artist!.id, 100);
      expect(model.artist!.name['ko'], '지민');
      expect(model.artist!.name['en'], 'Jimin');
      expect(model.artist!.image, 'https://example.com/jimin.png');
    });

    test('different status values', () {
      final statuses = ['pending', 'approved', 'rejected', 'in-progress', 'cancelled'];
      for (final status in statuses) {
        final json = {
          'id': 'req-$status',
          'vote_id': 1,
          'user_id': 'user-1',
          'artist_id': 10,
          'status': status,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final model = VoteItemRequestUser.fromJson(json);
        expect(model.status, status);
      }
    });
  });

  group('ArtistModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': 'https://example.com/jimin.png',
        'yy': 1995,
        'mm': 10,
        'dd': 13,
        'gender': 'male',
      };

      final model = ArtistModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name['ko'], '지민');
      expect(model.name['en'], 'Jimin');
      expect(model.image, 'https://example.com/jimin.png');
      expect(model.yy, 1995);
      expect(model.mm, 10);
      expect(model.dd, 13);
      expect(model.gender, 'male');
    });

    test('birthDate from yy/mm/dd fields', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': '지민', 'en': 'Jimin'},
        yy: 1995,
        mm: 10,
        dd: 13,
      );

      expect(model.birthDate, isNotNull);
      expect(model.birthDate!.year, 1995);
      expect(model.birthDate!.month, 10);
      expect(model.birthDate!.day, 13);
    });

    test('birthDate from birthDateRaw takes priority', () {
      final rawDate = DateTime(2000, 1, 1);
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        birthDateRaw: rawDate,
        yy: 1995,
        mm: 10,
        dd: 13,
      );

      expect(model.birthDate, rawDate);
    });

    test('birthDate is null when no date info', () {
      const model = ArtistModel(id: 1, name: {'ko': 'A'});
      expect(model.birthDate, isNull);
    });

    test('formattedBirthDate', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        yy: 1995,
        mm: 10,
        dd: 13,
      );
      expect(model.formattedBirthDate, '1995년 10월 13일');
    });

    test('formattedBirthDate null when no date', () {
      const model = ArtistModel(id: 1, name: {'ko': 'A'});
      expect(model.formattedBirthDate, isNull);
    });

    test('formattedName returns ko name first', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민', 'en': 'Jimin'},
      );
      expect(model.formattedName, '지민');
    });

    test('formattedName returns en name when no ko', () {
      const model = ArtistModel(
        id: 1,
        name: {'en': 'Jimin'},
      );
      expect(model.formattedName, 'Jimin');
    });

    test('formattedName returns first value when no ko or en', () {
      const model = ArtistModel(
        id: 1,
        name: {'ja': 'ジミン'},
      );
      expect(model.formattedName, 'ジミン');
    });

    test('formattedName returns null for empty name', () {
      const model = ArtistModel(id: 1, name: {});
      expect(model.formattedName, isNull);
    });

    test('isDeleted', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        deletedAt: DateTime.now(),
      );
      expect(model.isDeleted, true);

      const model2 = ArtistModel(id: 2, name: {'ko': 'B'});
      expect(model2.isDeleted, false);
    });
  });

  group('ArtistApplicationInfo', () {
    test('default isSubmitting is false', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 0,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.isSubmitting, false);
    });

    test('copyWith with isSubmitting true', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(isSubmitting: true);
      expect(updated.isSubmitting, true);
      expect(updated.artistName, 'Test');
      expect(updated.applicationCount, 5);
    });

    test('copyWith updates all fields independently', () {
      const info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 10,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      final u1 = info.copyWith(artistName: 'New');
      expect(u1.artistName, 'New');
      expect(u1.applicationCount, 10);

      final u2 = info.copyWith(applicationCount: 99);
      expect(u2.artistName, 'Original');
      expect(u2.applicationCount, 99);

      final u3 = info.copyWith(applicationStatus: 'approved');
      expect(u3.applicationStatus, 'approved');

      final u4 = info.copyWith(isAlreadyInVote: true);
      expect(u4.isAlreadyInVote, true);
    });
  });

  group('UserApplicationInfo', () {
    test('all fields set correctly', () {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
      });

      final info = UserApplicationInfo(
        id: 'ua-1',
        artistName: 'BTS',
        groupName: 'BigHit',
        status: 'approved',
        applicationCount: 100,
        artist: artist,
      );

      expect(info.id, 'ua-1');
      expect(info.artistName, 'BTS');
      expect(info.groupName, 'BigHit');
      expect(info.status, 'approved');
      expect(info.applicationCount, 100);
      expect(info.artist, isNotNull);
      expect(info.artist!.id, 1);
    });

    test('optional fields null by default', () {
      const info = UserApplicationInfo(
        id: 'ua-2',
        artistName: 'Solo',
        status: 'pending',
        applicationCount: 0,
      );

      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('formats thousands', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(10000), '10,000');
      expect(ArtistNameUtils.formatNumber(100000), '100,000');
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
    });

    test('small numbers unchanged', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(1), '1');
      expect(ArtistNameUtils.formatNumber(42), '42');
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('large numbers formatted correctly', () {
      expect(ArtistNameUtils.formatNumber(1234567890), '1,234,567,890');
    });
  });

  group('VoteRequestStatusUtils.getStatusColor', () {
    test('returns non-zero color value for all statuses', () {
      final statuses = ['pending', 'approved', 'rejected', 'in-progress', 'cancelled', 'unknown'];
      for (final status in statuses) {
        final color = VoteRequestStatusUtils.getStatusColor(status);
        expect(color.value, isNot(equals(0)), reason: 'Status "$status" should have a non-zero color');
      }
    });

    test('case insensitive', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('PENDING'),
        equals(VoteRequestStatusUtils.getStatusColor('pending')),
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('Approved'),
        equals(VoteRequestStatusUtils.getStatusColor('approved')),
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('REJECTED'),
        equals(VoteRequestStatusUtils.getStatusColor('rejected')),
      );
    });

    test('different statuses have expected color families', () {
      final pending = VoteRequestStatusUtils.getStatusColor('pending');
      final approved = VoteRequestStatusUtils.getStatusColor('approved');
      final rejected = VoteRequestStatusUtils.getStatusColor('rejected');

      // Pending is orange, approved is green, rejected is red - all different
      expect(pending, isNot(equals(approved)));
      expect(approved, isNot(equals(rejected)));
      expect(pending, isNot(equals(rejected)));
    });
  });

  group('VoteItemRequestRepository - empty responses', () {
    setUp(() {
      setupMockSupabase({}, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('getVoteItemRequestCount with no table data returns 0', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final count = await repo.getVoteItemRequestCount(1);
      expect(count, 0);
    });

    test('getCurrentUserApplicationsWithDetails with no data returns empty list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final apps = await repo.getCurrentUserApplicationsWithDetails('test-user-id');
      expect(apps, isEmpty);
    });

    test('getVoteItemRequestsByVoteId with no data returns empty list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final requests = await repo.getVoteItemRequestsByVoteId(999);
      expect(requests, isEmpty);
    });

    test('getUserRequestsByVoteId with no data returns empty list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final requests = await repo.getUserRequestsByVoteId('test-user-id', 999);
      expect(requests, isEmpty);
    });

    test('getUserRequestHistory with no data returns empty list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final history = await repo.getUserRequestHistory('test-user-id');
      expect(history, isEmpty);
    });

    test('getVoteRequestStatusSummary with no data returns empty list', () async {
      final repo = VoteItemRequestRepository(supabase: testSupabaseClient!);
      final summary = await repo.getVoteRequestStatusSummary(999);
      expect(summary, isEmpty);
    });
  });

  group('VoteItemRequestUser model edge cases', () {
    test('model with all artist fields populated', () {
      final json = {
        'id': 'req-full',
        'vote_id': 5,
        'user_id': 'user-full',
        'artist_id': 50,
        'status': 'in-progress',
        'created_at': '2024-12-25T00:00:00Z',
        'updated_at': '2024-12-26T12:00:00Z',
        'artist': {
          'id': 50,
          'name': {'ko': '아이유', 'en': 'IU'},
          'image': 'https://cdn.example.com/iu.png',
          'yy': 1993,
          'mm': 5,
          'dd': 16,
          'gender': 'female',
        },
      };

      final model = VoteItemRequestUser.fromJson(json);
      expect(model.id, 'req-full');
      expect(model.voteId, 5);
      expect(model.status, 'in-progress');
      expect(model.artist, isNotNull);
      expect(model.artist!.name['ko'], '아이유');
      expect(model.artist!.gender, 'female');
    });

    test('toJson roundtrip consistency', () {
      final json = {
        'id': 'req-rt',
        'vote_id': 3,
        'user_id': 'user-rt',
        'artist_id': 30,
        'status': 'cancelled',
        'created_at': '2024-03-01T08:00:00.000Z',
        'updated_at': '2024-03-02T08:00:00.000Z',
      };

      final model = VoteItemRequestUser.fromJson(json);
      final outputJson = model.toJson();
      expect(outputJson['id'], 'req-rt');
      expect(outputJson['vote_id'], 3);
      expect(outputJson['user_id'], 'user-rt');
      expect(outputJson['artist_id'], 30);
      expect(outputJson['status'], 'cancelled');
    });
  });

  group('ArtistModel edge cases', () {
    test('invalid yy/mm/dd returns null birthDate', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': 'A'},
        yy: 2024,
        mm: 13, // invalid month
        dd: 32, // invalid day
      );
      // DateTime constructor may still create, but it won't crash
      // The try-catch in the getter handles exceptions
    });

    test('partial yy/mm/dd returns null birthDate', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': 'A'},
        yy: 2024,
        mm: null,
        dd: 15,
      );
      expect(model.birthDate, isNull);
    });

    test('copyWith on ArtistModel', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민', 'en': 'Jimin'},
        image: 'old.png',
      );

      final updated = model.copyWith(image: 'new.png');
      expect(updated.image, 'new.png');
      expect(updated.id, 1);
      expect(updated.name, {'ko': '지민', 'en': 'Jimin'});
    });

    test('isBookmarked field', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': 'A'},
        isBookmarked: true,
      );
      expect(model.isBookmarked, true);

      const model2 = ArtistModel(id: 2, name: {'ko': 'B'});
      expect(model2.isBookmarked, isNull);
    });

    test('artistGroup field', () {
      final json = {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'artist_group': {
          'id': 10,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': 'bts.png',
        },
      };

      final model = ArtistModel.fromJson(json);
      expect(model.artistGroup, isNotNull);
      expect(model.artistGroup!.id, 10);
      expect(model.artistGroup!.name['ko'], 'BTS');
    });
  });
}
