import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
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

  testWidgets('artist summaries preserve the consumed aggregate shape',
      (tester) async {
    setupMockSupabase({
      'vote_item_request_status_summary': [
        {'vote_id': 1, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': 4},
        {'vote_id': 1, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'approved', 'request_count': 3},
        {'vote_id': 1, 'artist_id': 11, 'artist_name': '가수 A', 'request_status': 'rejected', 'request_count': 2},
      ],
      'vote_item_request_users': [
        {'id': 'current-request', 'vote_id': 1, 'user_id': 'current-user', 'artist_id': 10, 'status': 'pending', 'created_at': '2024-01-15T10:00:00Z', 'updated_at': '2024-01-15T10:00:00Z'},
      ],
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

    final result = await VoteItemRequestService(
      ref: widgetRef,
      voteId: '1',
      supabase: testSupabaseClient!,
    ).loadAllApplicationsByArtist();
    final summaries = result['artistApplicationSummaries'] as List<Map<String, dynamic>>;

    expect(result['totalApplications'], 9);
    expect(summaries.map((summary) => summary['artistId']), [10, 11]);
    expect(summaries.first['artist'], {'id': 10, 'name': {'ko': '가수 A'}});
    expect(summaries.last['artist'], {'id': 11, 'name': {'ko': '가수 A'}});
    expect(summaries.first, containsPair('totalApplications', 7));
    expect(summaries.first, containsPair('pendingCount', 4));
    expect(summaries.first, containsPair('approvedCount', 3));
    expect(summaries.first.containsKey('requests'), isFalse);
    expect(summaries.first.containsKey('latestRequest'), isFalse);
  });

  group('ArtistApplicationInfo - copyWith comprehensive', () {
    test('copyWith preserves all unchanged fields', () {
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

    test('copyWith updates single field at a time', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      expect(info.copyWith(artistName: 'Updated').artistName, 'Updated');
      expect(info.copyWith(applicationCount: 99).applicationCount, 99);
      expect(info.copyWith(applicationStatus: 'approved').applicationStatus, 'approved');
      expect(info.copyWith(isAlreadyInVote: true).isAlreadyInVote, true);
      expect(info.copyWith(isSubmitting: true).isSubmitting, true);
    });

    test('copyWith updates multiple fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 0,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
        isSubmitting: false,
      );

      final updated = info.copyWith(
        artistName: 'New Name',
        applicationCount: 50,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );

      expect(updated.artistName, 'New Name');
      expect(updated.applicationCount, 50);
      expect(updated.applicationStatus, 'approved');
      expect(updated.isAlreadyInVote, true);
      expect(updated.isSubmitting, true);
    });
  });

  group('ArtistNameUtils.formatNumber edge cases', () {
    test('formats zero', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
    });

    test('formats single digit', () {
      expect(ArtistNameUtils.formatNumber(5), '5');
    });

    test('formats hundreds', () {
      expect(ArtistNameUtils.formatNumber(100), '100');
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('formats thousands boundary', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(9999), '9,999');
    });

    test('formats ten thousands', () {
      expect(ArtistNameUtils.formatNumber(10000), '10,000');
      expect(ArtistNameUtils.formatNumber(99999), '99,999');
    });

    test('formats millions', () {
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
    });

    test('formats billions', () {
      expect(ArtistNameUtils.formatNumber(1234567890), '1,234,567,890');
    });
  });

  group('VoteRequestStatusUtils.getStatusColor comprehensive', () {
    test('pending returns orange', () {
      final color = VoteRequestStatusUtils.getStatusColor('pending');
      // Orange color has high red and green components
      expect(color.r, greaterThan(0.5));
    });

    test('approved returns green', () {
      final color = VoteRequestStatusUtils.getStatusColor('approved');
      expect(color.g, greaterThan(0.3));
    });

    test('rejected returns red', () {
      final color = VoteRequestStatusUtils.getStatusColor('rejected');
      expect(color.r, greaterThan(0.5));
    });

    test('in-progress returns primary color', () {
      final color = VoteRequestStatusUtils.getStatusColor('in-progress');
      expect(color, isNotNull);
    });

    test('cancelled returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('cancelled');
      expect(color, isNotNull);
    });

    test('unknown status returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('something_unknown');
      expect(color, isNotNull);
    });

    test('empty string returns grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('');
      expect(color, isNotNull);
    });
  });

  group('UserApplicationInfo', () {
    test('all fields populated', () {
      const model = ArtistModel(
        id: 42,
        name: {'ko': '태연', 'en': 'Taeyeon'},
      );

      final info = UserApplicationInfo(
        id: 'app-1',
        artistName: '태연',
        groupName: '소녀시대',
        status: 'approved',
        applicationCount: 100,
        artist: model,
      );

      expect(info.id, 'app-1');
      expect(info.artistName, '태연');
      expect(info.groupName, '소녀시대');
      expect(info.status, 'approved');
      expect(info.applicationCount, 100);
      expect(info.artist, isNotNull);
      expect(info.artist!.id, 42);
    });

    test('optional fields default to null', () {
      const info = UserApplicationInfo(
        id: 'app-2',
        artistName: 'Solo',
        status: 'pending',
        applicationCount: 0,
      );

      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('zero application count', () {
      const info = UserApplicationInfo(
        id: 'app-3',
        artistName: 'New',
        status: 'pending',
        applicationCount: 0,
      );
      expect(info.applicationCount, 0);
    });

    test('large application count', () {
      const info = UserApplicationInfo(
        id: 'app-4',
        artistName: 'Popular',
        status: 'approved',
        applicationCount: 999999,
      );
      expect(info.applicationCount, 999999);
    });
  });

  group('ArtistModel - formattedName', () {
    test('returns ko when both available', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민', 'en': 'Jimin'},
      );
      expect(model.formattedName, '지민');
    });

    test('returns en when ko not available', () {
      const model = ArtistModel(
        id: 1,
        name: {'en': 'Jimin'},
      );
      expect(model.formattedName, 'Jimin');
    });

    test('returns first value when neither ko nor en', () {
      const model = ArtistModel(
        id: 1,
        name: {'ja': 'ジミン'},
      );
      expect(model.formattedName, 'ジミン');
    });

    test('returns null for empty name map', () {
      const model = ArtistModel(id: 1, name: {});
      expect(model.formattedName, isNull);
    });
  });

  group('ArtistModel - birthDate', () {
    test('birthDateRaw takes priority over yy/mm/dd', () {
      final raw = DateTime(2000, 6, 15);
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        birthDateRaw: raw,
        yy: 1990,
        mm: 1,
        dd: 1,
      );
      expect(model.birthDate, raw);
    });

    test('yy/mm/dd creates valid birthDate', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        yy: 1995,
        mm: 10,
        dd: 13,
      );
      expect(model.birthDate, isNotNull);
      expect(model.birthDate!.year, 1995);
      expect(model.birthDate!.month, 10);
      expect(model.birthDate!.day, 13);
    });

    test('partial yy/mm/dd returns null', () {
      const modelOnlyYy = ArtistModel(
        id: 1,
        name: {'ko': 'A'},
        yy: 1995,
      );
      expect(modelOnlyYy.birthDate, isNull);

      const modelYyMm = ArtistModel(
        id: 1,
        name: {'ko': 'A'},
        yy: 1995,
        mm: 10,
      );
      expect(modelYyMm.birthDate, isNull);
    });

    test('no date info returns null', () {
      const model = ArtistModel(id: 1, name: {'ko': 'A'});
      expect(model.birthDate, isNull);
    });
  });

  group('ArtistModel - formattedBirthDate', () {
    test('formats correctly', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        yy: 2000,
        mm: 1,
        dd: 5,
      );
      expect(model.formattedBirthDate, '2000년 1월 5일');
    });

    test('returns null when no birthDate', () {
      const model = ArtistModel(id: 1, name: {'ko': 'A'});
      expect(model.formattedBirthDate, isNull);
    });
  });

  group('ArtistModel - isDeleted', () {
    test('true when deletedAt is set', () {
      final model = ArtistModel(
        id: 1,
        name: const {'ko': 'A'},
        deletedAt: DateTime.now(),
      );
      expect(model.isDeleted, true);
    });

    test('false when deletedAt is null', () {
      const model = ArtistModel(id: 1, name: {'ko': 'A'});
      expect(model.isDeleted, false);
    });
  });

  group('ArtistModel - fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 42,
        'name': {'ko': '아이유', 'en': 'IU'},
        'image': 'https://example.com/iu.png',
        'yy': 1993,
        'mm': 5,
        'dd': 16,
        'gender': 'female',
        'artist_group': {
          'id': 10,
          'name': {'ko': '솔로', 'en': 'Solo'},
        },
      };

      final model = ArtistModel.fromJson(json);
      expect(model.id, 42);
      expect(model.name['ko'], '아이유');
      expect(model.image, 'https://example.com/iu.png');
      expect(model.yy, 1993);
      expect(model.mm, 5);
      expect(model.dd, 16);
      expect(model.gender, 'female');
      expect(model.artistGroup, isNotNull);
      expect(model.artistGroup!.id, 10);
    });

    test('parses minimal fields', () {
      final json = {
        'id': 1,
        'name': {'ko': 'A'},
      };

      final model = ArtistModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name['ko'], 'A');
      expect(model.image, isNull);
      expect(model.yy, isNull);
      expect(model.artistGroup, isNull);
    });
  });

  group('ArtistModel - toJson', () {
    test('serializes correctly', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민', 'en': 'Jimin'},
        image: 'test.png',
        yy: 1995,
        mm: 10,
        dd: 13,
      );

      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['name'], {'ko': '지민', 'en': 'Jimin'});
    });
  });

  group('ArtistModel - copyWith', () {
    test('copies with new image', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민'},
        image: 'old.png',
      );

      final updated = model.copyWith(image: 'new.png');
      expect(updated.image, 'new.png');
      expect(updated.id, 1);
    });

    test('copies with new isBookmarked', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '지민'},
      );

      final updated = model.copyWith(isBookmarked: true);
      expect(updated.isBookmarked, true);
    });
  });

  group('Supabase integration - checkIfArtistInVoteItems logic', () {
    setUp(() {
      setupMockSupabase({
        'vote_item': [
          {
            'id': 1,
            'vote_id': 10,
            'artist': {
              'name': {'ko': '지민', 'en': 'Jimin'},
            },
          },
          {
            'id': 2,
            'vote_id': 10,
            'artist': {
              'name': {'ko': '뷔', 'en': 'V'},
            },
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('Supabase client returns vote items', () async {
      final response = await testSupabaseClient!
          .from('vote_item')
          .select('id, artist!inner(name)')
          .eq('vote_id', 10);

      expect(response, isA<List>());
      expect(response.length, 2);
    });
  });

  group('Supabase integration - application data batch loading', () {
    setUp(() {
      setupMockSupabase({
        'vote_item_request_users': [
          {
            'artist': {
              'name': {'ko': '지민', 'en': 'Jimin'},
            },
          },
          {
            'artist': {
              'name': {'ko': '지민', 'en': 'Jimin'},
            },
          },
          {
            'artist': {
              'name': {'ko': '뷔', 'en': 'V'},
            },
          },
        ],
        'vote_item': [
          {
            'artist': {
              'name': {'ko': '지민', 'en': 'Jimin'},
            },
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() => tearDownMockSupabase());

    test('can query vote_item_request_users', () async {
      final response = await testSupabaseClient!
          .from('vote_item_request_users')
          .select('artist!inner(name)')
          .eq('vote_id', '10');

      expect(response, isA<List>());
    });
  });
}
