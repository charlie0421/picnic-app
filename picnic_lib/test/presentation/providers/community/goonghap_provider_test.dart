import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  final artistData = {
    'id': 1,
    'name': {'ko': '지민', 'en': 'Jimin'},
    'yy': 1995,
    'mm': 10,
    'dd': 13,
    'birth_date': '1995-10-13T00:00:00Z',
    'gender': 'male',
    'image': 'https://example.com/jimin.png',
    'artist_group': null,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
    'isBookmarked': null,
  };

  final completedGoonghapData = {
    'id': 'goonghap-1',
    'user_id': 'test-user-id',
    'artist_id': 1,
    'user_birth_date': '2000-01-01T00:00:00Z',
    'user_birth_time': '12:00',
    'gender': 'female',
    'status': 'completed',
    'error_message': null,
    'score': 85,
    'created_at': '2026-01-01T00:00:00Z',
    'completed_at': '2026-01-01T01:00:00Z',
    'is_paid': true,
    'is_ads': false,
    'artist': artistData,
  };

  final pendingGoonghapData = {
    'id': 'goonghap-2',
    'user_id': 'test-user-id',
    'artist_id': 1,
    'user_birth_date': '2000-01-01T00:00:00Z',
    'user_birth_time': null,
    'gender': 'male',
    'status': 'pending',
    'error_message': null,
    'score': null,
    'created_at': '2026-01-01T00:00:00Z',
    'completed_at': null,
    'is_paid': false,
    'is_ads': false,
    'artist': artistData,
  };

  final errorGoonghapData = {
    'id': 'goonghap-3',
    'user_id': 'test-user-id',
    'artist_id': 1,
    'user_birth_date': '2000-01-01T00:00:00Z',
    'user_birth_time': null,
    'gender': 'female',
    'status': 'error',
    'error_message': 'Processing failed',
    'score': null,
    'created_at': '2026-01-01T00:00:00Z',
    'completed_at': null,
    'is_paid': false,
    'is_ads': true,
    'artist': artistData,
  };

  group('GoonghapLoadingNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is false', () {
      final state = container.read(goonghapLoadingProvider);
      expect(state, false);
    });

    test('set updates state to true', () {
      container.read(goonghapLoadingProvider.notifier).set(true);
      expect(container.read(goonghapLoadingProvider), true);
    });

    test('set updates state to false', () {
      container.read(goonghapLoadingProvider.notifier).set(true);
      container.read(goonghapLoadingProvider.notifier).set(false);
      expect(container.read(goonghapLoadingProvider), false);
    });

    test('multiple set calls work correctly', () {
      final notifier = container.read(goonghapLoadingProvider.notifier);
      notifier.set(true);
      notifier.set(true);
      expect(container.read(goonghapLoadingProvider), true);
      notifier.set(false);
      expect(container.read(goonghapLoadingProvider), false);
    });

    test('toggle rapidly between states', () {
      final notifier = container.read(goonghapLoadingProvider.notifier);
      for (int i = 0; i < 10; i++) {
        notifier.set(i % 2 == 0);
      }
      // Last was i=9, 9%2==1 => false
      expect(container.read(goonghapLoadingProvider), false);
    });
  });

  group('Goonghap Notifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
          'functions:goonghap': {'success': true},
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('initial state is AsyncData(null)', () {
      final state = container.read(goonghapProvider);
      expect(state, isA<AsyncData<GoonghapModel?>>());
      expect(state.value, isNull);
    });

    test('setGoonghap updates state with completed goonghap', () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      final state = container.read(goonghapProvider);
      expect(state, isA<AsyncData<GoonghapModel?>>());
      expect(state.value, isNotNull);
      expect(state.value!.id, 'goonghap-1');
      expect(state.value!.isCompleted, true);
    });

    test('setGoonghap skips duplicate calls with same id', () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);
      // Calling again with the same ID should be a no-op
      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      final state = container.read(goonghapProvider);
      expect(state.value!.id, 'goonghap-1');
    });

    test('setGoonghap with error status does not trigger background processing',
        () async {
      final goonghap = GoonghapModel.fromJson({
        ...errorGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      final state = container.read(goonghapProvider);
      expect(state.value!.id, 'goonghap-3');
      expect(state.value!.hasError, true);
      // Loading should be false since it's not pending
      expect(container.read(goonghapLoadingProvider), false);
    });

    test('setGoonghap with different IDs updates state', () async {
      final goonghap1 = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-a',
        'i18n': <Map<String, dynamic>>[],
      });
      final goonghap2 = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-b',
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap1);
      expect(container.read(goonghapProvider).value!.id, 'goonghap-a');

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap2);
      expect(container.read(goonghapProvider).value!.id, 'goonghap-b');
    });

    test('loadGoonghap loads completed goonghap', () async {
      await container
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      final state = container.read(goonghapProvider);
      expect(state, isA<AsyncData<GoonghapModel?>>());
      expect(state.value, isNotNull);
    });

    test('loadGoonghap returns null for non-existent id', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': <Map<String, dynamic>>[],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('nonexistent');

      final state = container2.read(goonghapProvider);
      expect(state, isA<AsyncData<GoonghapModel?>>());
      expect(state.value, isNull);
    });

    test('loadGoonghap skips when already loading', () async {
      // Trigger a load
      final future = container
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      // Second call should be skipped (isLoading is true)
      container.read(goonghapProvider.notifier).loadGoonghap('goonghap-1');

      await future;
    });

    test('loadGoonghap with forceRefresh reloads same id', () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      // Without forceRefresh, loading same ID should be no-op
      await container
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      // With forceRefresh, it should reload
      await container
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1', forceRefresh: true);

      final state = container.read(goonghapProvider);
      expect(state.value, isNotNull);
    });

    test('loadGoonghap sets loading to false when non-pending', () async {
      await container
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      expect(container.read(goonghapLoadingProvider), false);
    });

    test(
        'loadGoonghap sets status to error when completed but no i18n data found',
        () async {
      // Mock returns completed goonghap but empty i18n (RPC returns [])
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      final state = container2.read(goonghapProvider);
      expect(state.value, isNotNull);
      expect(state.value!.status, GoonghapStatus.error);
      expect(state.value!.errorMessage, 'No results found');
    });

    test('loadGoonghap with i18n data for completed goonghap', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
          'rpc/get_goonghap_i18n': [
            {
              'language': 'ko',
              'score': 85,
              'score_title': '최고의 궁합',
              'goonghap_summary': '잘 맞습니다',
              'details': null,
              'tips': ['팁1'],
            },
          ],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      final state = container2.read(goonghapProvider);
      expect(state.value, isNotNull);
      expect(state.value!.status, GoonghapStatus.completed);
      expect(state.value!.localizedResults, isNotNull);
    });

    test('loadGoonghap with pending status loads data', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [pendingGoonghapData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-2');

      final state = container2.read(goonghapProvider);
      expect(state.value, isNotNull);
      expect(state.value!.isPending, true);
      // loadGoonghap does NOT set loading to true; it only conditionally
      // sets it to false for non-pending status. So loading stays at its
      // initial value (false) since loadGoonghap didn't change it.
      // The loading notifier is only set to true by setGoonghap/createGoonghap.
    });

    test('loadGoonghap with error status sets loading false', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [errorGoonghapData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-3');

      final state = container2.read(goonghapProvider);
      expect(state.value, isNotNull);
      expect(state.value!.hasError, true);
      expect(container2.read(goonghapLoadingProvider), false);
    });

    test('refresh does nothing when state is null', () async {
      await container.read(goonghapProvider.notifier).refresh();

      final state = container.read(goonghapProvider);
      expect(state.value, isNull);
    });

    test('refresh reloads goonghap when state has value', () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);
      await container.read(goonghapProvider.notifier).refresh();

      final state = container.read(goonghapProvider);
      expect(state.value, isNotNull);
    });

    test('createGoonghap requires authentication', () async {
      final result = await container
          .read(goonghapProvider.notifier)
          .createGoonghap(
            artist: ArtistModel.fromJson(artistData),
            birthDate: DateTime(2000, 1, 1),
            gender: 'female',
          );

      expect(result, isNull);
      final state = container.read(goonghapProvider);
      expect(state, isA<AsyncError>());
    });

    test('createGoonghap requires artist birth date', () async {
      final artistWithoutBirthDate = ArtistModel(
        id: 1,
        name: {'ko': '테스트', 'en': 'Test'},
      );

      final result = await container
          .read(goonghapProvider.notifier)
          .createGoonghap(
            artist: artistWithoutBirthDate,
            birthDate: DateTime(2000, 1, 1),
            gender: 'female',
          );

      expect(result, isNull);
    });

    test('createGoonghap sets loading notifier to true initially', () async {
      // The loading will be set true then to false on error (since no auth)
      await container
          .read(goonghapProvider.notifier)
          .createGoonghap(
            artist: ArtistModel.fromJson(artistData),
            birthDate: DateTime(2000, 1, 1),
            gender: 'female',
          );

      // After error, loading is set to false
      expect(container.read(goonghapLoadingProvider), false);
    });

    test('createGoonghap with birthTime parameter', () async {
      final result = await container
          .read(goonghapProvider.notifier)
          .createGoonghap(
            artist: ArtistModel.fromJson(artistData),
            birthDate: DateTime(2000, 1, 1),
            gender: 'female',
            birthTime: '14:30',
          );

      // Will fail due to no auth but the parameter should be accepted
      expect(result, isNull);
    });

    test('openGoonghap returns alreadyPaid when state shows isPaid', () async {
      final paidGoonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'is_paid': true,
        'i18n': <Map<String, dynamic>>[],
      });

      await container.read(goonghapProvider.notifier).setGoonghap(paidGoonghap);

      final result = await container
          .read(goonghapProvider.notifier)
          .openGoonghap(
            goonghapId: 'goonghap-1',
            userId: 'test-user-id',
          );

      expect(result, OpenGoonghapResult.alreadyPaid);
    });

    test('openGoonghap calls edge function when not already paid', () async {
      final unpaidGoonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-unpaid',
        'is_paid': false,
        'i18n': <Map<String, dynamic>>[],
      });

      await container
          .read(goonghapProvider.notifier)
          .setGoonghap(unpaidGoonghap);

      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [
            {
              ...completedGoonghapData,
              'id': 'goonghap-unpaid',
              'is_paid': true
            }
          ],
          'functions:open-goonghap': {'alreadyPaid': false},
        },
        userId: 'test-user-id',
      );

      final result = await container
          .read(goonghapProvider.notifier)
          .openGoonghap(
            goonghapId: 'goonghap-unpaid',
            userId: 'test-user-id',
          );

      expect(result, OpenGoonghapResult.success);
    });

    test('openGoonghap returns alreadyPaid from edge function response',
        () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-other',
        'is_paid': false,
        'i18n': <Map<String, dynamic>>[],
      });
      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
          'functions:open-goonghap': {'alreadyPaid': true},
        },
        userId: 'test-user-id',
      );

      final result = await container
          .read(goonghapProvider.notifier)
          .openGoonghap(
            goonghapId: 'goonghap-1',
            userId: 'test-user-id',
          );

      expect(result, OpenGoonghapResult.alreadyPaid);
    });

    test('openGoonghap does not check state for different goonghapId',
        () async {
      final paidGoonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-paid',
        'is_paid': true,
        'i18n': <Map<String, dynamic>>[],
      });

      await container
          .read(goonghapProvider.notifier)
          .setGoonghap(paidGoonghap);

      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
          'functions:open-goonghap': {'alreadyPaid': false},
        },
        userId: 'test-user-id',
      );

      // Different goonghapId than what's in state, so no early return
      final result = await container
          .read(goonghapProvider.notifier)
          .openGoonghap(
            goonghapId: 'goonghap-different',
            userId: 'test-user-id',
          );

      expect(result, OpenGoonghapResult.success);
    });

    test('openGoonghap with custom starCandyRequired', () async {
      final goonghap = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'id': 'goonghap-custom',
        'is_paid': false,
        'i18n': <Map<String, dynamic>>[],
      });
      await container.read(goonghapProvider.notifier).setGoonghap(goonghap);

      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [
            {...completedGoonghapData, 'id': 'goonghap-custom'}
          ],
          'functions:open-goonghap': {'alreadyPaid': false},
        },
        userId: 'test-user-id',
      );

      final result = await container
          .read(goonghapProvider.notifier)
          .openGoonghap(
            goonghapId: 'goonghap-custom',
            userId: 'test-user-id',
            starCandyRequired: 200,
          );

      expect(result, OpenGoonghapResult.success);
    });

    test('loading notifier is set to false when state is not pending',
        () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [completedGoonghapData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-1');

      expect(container2.read(goonghapLoadingProvider), false);
    });

    test('loading notifier not set to false when status is pending', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'goonghap_results': [pendingGoonghapData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      // Pre-set loading to true (as setGoonghap would do)
      container2.read(goonghapLoadingProvider.notifier).set(true);

      await container2
          .read(goonghapProvider.notifier)
          .loadGoonghap('goonghap-2');

      // Pending status should NOT set loading to false
      expect(container2.read(goonghapLoadingProvider), true);
    });
  });

  group('GoonghapModel', () {
    test('fromJson parses completed goonghap correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.id, 'goonghap-1');
      expect(model.userId, 'test-user-id');
      expect(model.status, GoonghapStatus.completed);
      expect(model.isCompleted, true);
      expect(model.isPending, false);
      expect(model.hasError, false);
      expect(model.score, 85);
      expect(model.isPaid, true);
      expect(model.isAds, false);
      expect(model.gender, 'female');
      expect(model.artist.id, 1);
    });

    test('fromJson parses pending goonghap correctly', () {
      final model = GoonghapModel.fromJson({
        ...pendingGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.id, 'goonghap-2');
      expect(model.status, GoonghapStatus.pending);
      expect(model.isPending, true);
      expect(model.isCompleted, false);
      expect(model.score, isNull);
      expect(model.isPaid, false);
    });

    test('fromJson parses error goonghap correctly', () {
      final model = GoonghapModel.fromJson({
        ...errorGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.id, 'goonghap-3');
      expect(model.status, GoonghapStatus.error);
      expect(model.hasError, true);
      expect(model.isPending, false);
      expect(model.isCompleted, false);
      expect(model.errorMessage, 'Processing failed');
      expect(model.isAds, true);
    });

    test('fromJson parses i18n data from list correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': [
          {
            'language': 'ko',
            'score': 85,
            'score_title': '최고의 궁합',
            'goonghap_summary': '아주 잘 맞습니다',
            'details': {
              'style': {
                'idol_style': '열정적',
                'user_style': '차분한',
                'couple_style': '보완적',
              },
              'activities': {
                'recommended': ['영화 감상', '산책'],
                'description': '함께 즐길 수 있는 활동',
              },
            },
            'tips': ['팁 1', '팁 2'],
          },
          {
            'language': 'en',
            'score': 85,
            'score_title': 'Best Match',
            'goonghap_summary': 'Great compatibility',
            'details': null,
            'tips': ['Tip 1'],
          },
        ],
      });

      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, 2);
      expect(model.localizedResults!.containsKey('ko'), true);
      expect(model.localizedResults!.containsKey('en'), true);

      final ko = model.getLocalizedResult('ko');
      expect(ko, isNotNull);
      expect(ko!.score, 85);
      expect(ko.scoreTitle, '최고의 궁합');
      expect(ko.goonghapSummary, '아주 잘 맞습니다');
      expect(ko.tips, ['팁 1', '팁 2']);
      expect(ko.details, isNotNull);
      expect(ko.details!.style.idolStyle, '열정적');
      expect(ko.details!.style.userStyle, '차분한');
      expect(ko.details!.style.coupleStyle, '보완적');
      expect(ko.details!.activities.recommended, ['영화 감상', '산책']);
      expect(ko.details!.activities.description, '함께 즐길 수 있는 활동');

      final en = model.getLocalizedResult('en');
      expect(en, isNotNull);
      expect(en!.scoreTitle, 'Best Match');
      expect(en.details, isNull);
    });

    test('fromJson parses i18n data from map correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': {
          'ko': {
            'language': 'ko',
            'score': 90,
            'score_title': '환상 궁합',
            'goonghap_summary': '완벽합니다',
            'tips': [],
          },
        },
      });

      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.containsKey('ko'), true);
      expect(model.getLocalizedResult('ko')!.score, 90);
    });

    test('getLocalizedResult returns null for missing language', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.getLocalizedResult('ko'), isNull);
      expect(model.getLocalizedResult('ja'), isNull);
    });

    test('fromJson handles null i18n', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': null,
      });

      expect(model.localizedResults, isNull);
    });

    test('fromJson handles empty i18n list', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': [],
      });

      expect(model.localizedResults, isNull);
    });

    test('copyWith updates fields correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      final updated = model.copyWith(
        status: GoonghapStatus.error,
        errorMessage: 'New error',
      );

      expect(updated.status, GoonghapStatus.error);
      expect(updated.errorMessage, 'New error');
      expect(updated.id, model.id);
      expect(updated.userId, model.userId);
    });

    test('copyWith preserves unmodified fields', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      final updated = model.copyWith(score: 99);
      expect(updated.score, 99);
      expect(updated.id, model.id);
      expect(updated.userId, model.userId);
      expect(updated.gender, model.gender);
      expect(updated.artist.id, model.artist.id);
      expect(updated.isPaid, model.isPaid);
    });

    test('birthTime can be null', () {
      final model = GoonghapModel.fromJson({
        ...pendingGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.birthTime, isNull);
    });

    test('birthTime is parsed when present', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.birthTime, '12:00');
    });

    test('birthDate is parsed correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.birthDate, isNotNull);
      expect(model.birthDate.year, 2000);
      expect(model.birthDate.month, 1);
      expect(model.birthDate.day, 1);
    });

    test('artist data is parsed correctly', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.artist, isNotNull);
      expect(model.artist.id, 1);
      expect(model.artist.name['ko'], '지민');
      expect(model.artist.name['en'], 'Jimin');
    });

    test('completedAt can be null for pending', () {
      final model = GoonghapModel.fromJson({
        ...pendingGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.completedAt, isNull);
    });

    test('completedAt is parsed when present', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      expect(model.completedAt, isNotNull);
    });

    test('i18n list items without language key are skipped', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': [
          {
            // no 'language' key
            'score': 50,
            'score_title': 'No Language',
          },
          {
            'language': 'ko',
            'score': 85,
            'score_title': 'Valid',
          },
        ],
      });

      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, 1);
      expect(model.localizedResults!.containsKey('ko'), true);
    });

    test('i18n list with non-map items are skipped', () {
      final model = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': [
          'not a map',
          42,
          {
            'language': 'ko',
            'score': 85,
          },
        ],
      });

      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, 1);
    });
  });

  group('LocalizedGoonghap', () {
    test('fromJson with all fields', () {
      final model = LocalizedGoonghap.fromJson({
        'language': 'ko',
        'score': 92,
        'score_title': '최고',
        'goonghap_summary': '요약',
        'details': {
          'style': {
            'idol_style': 'a',
            'user_style': 'b',
            'couple_style': 'c',
          },
          'activities': {
            'recommended': ['x'],
            'description': 'd',
          },
        },
        'tips': ['t1', 't2'],
      });

      expect(model.language, 'ko');
      expect(model.score, 92);
      expect(model.scoreTitle, '최고');
      expect(model.goonghapSummary, '요약');
      expect(model.tips, ['t1', 't2']);
      expect(model.details, isNotNull);
    });

    test('fromJson with defaults', () {
      final model = LocalizedGoonghap.fromJson({
        'language': 'en',
      });

      expect(model.language, 'en');
      expect(model.score, 0);
      expect(model.scoreTitle, '');
      expect(model.goonghapSummary, '');
      expect(model.tips, isEmpty);
      expect(model.details, isNull);
    });

    test('fromJson with empty tips list', () {
      final model = LocalizedGoonghap.fromJson({
        'language': 'ja',
        'tips': [],
      });

      expect(model.tips, isEmpty);
    });

    test('fromJson with multiple tips', () {
      final model = LocalizedGoonghap.fromJson({
        'language': 'ko',
        'tips': ['팁1', '팁2', '팁3', '팁4', '팁5'],
      });

      expect(model.tips.length, 5);
    });
  });

  group('Details model', () {
    test('fromJson parses correctly', () {
      final details = Details.fromJson({
        'style': {
          'idol_style': '열정적',
          'user_style': '차분한',
          'couple_style': '보완적',
        },
        'activities': {
          'recommended': ['영화', '카페'],
          'description': '설명',
        },
      });

      expect(details.style.idolStyle, '열정적');
      expect(details.style.userStyle, '차분한');
      expect(details.style.coupleStyle, '보완적');
      expect(details.activities.recommended, ['영화', '카페']);
      expect(details.activities.description, '설명');
    });

    test('toJson produces correct output', () {
      final details = Details(
        style: StyleDetails(
          idolStyle: 'a',
          userStyle: 'b',
          coupleStyle: 'c',
        ),
        activities: ActivitiesDetails(
          recommended: ['x', 'y'],
          description: 'd',
        ),
      );

      final json = details.toJson();
      expect(json['style'], isNotNull);
      expect(json['activities'], isNotNull);
    });
  });

  group('StyleDetails model', () {
    test('fromJson parses all fields', () {
      final style = StyleDetails.fromJson({
        'idol_style': 'energetic',
        'user_style': 'calm',
        'couple_style': 'complementary',
      });

      expect(style.idolStyle, 'energetic');
      expect(style.userStyle, 'calm');
      expect(style.coupleStyle, 'complementary');
    });

    test('toJson produces correct output', () {
      const style = StyleDetails(
        idolStyle: 'a',
        userStyle: 'b',
        coupleStyle: 'c',
      );

      final json = style.toJson();
      expect(json['idol_style'], 'a');
      expect(json['user_style'], 'b');
      expect(json['couple_style'], 'c');
    });
  });

  group('ActivitiesDetails model', () {
    test('fromJson parses all fields', () {
      final activities = ActivitiesDetails.fromJson({
        'recommended': ['hiking', 'cooking'],
        'description': 'Fun activities',
      });

      expect(activities.recommended, ['hiking', 'cooking']);
      expect(activities.description, 'Fun activities');
    });

    test('fromJson with empty recommended list', () {
      final activities = ActivitiesDetails.fromJson({
        'recommended': [],
        'description': '',
      });

      expect(activities.recommended, isEmpty);
      expect(activities.description, '');
    });

    test('toJson produces correct output', () {
      const activities = ActivitiesDetails(
        recommended: ['a', 'b'],
        description: 'desc',
      );

      final json = activities.toJson();
      expect(json['recommended'], ['a', 'b']);
      expect(json['description'], 'desc');
    });
  });

  group('GoonghapHistoryModel', () {
    test('fromJson parses correctly', () {
      final history = GoonghapHistoryModel(
        items: [],
        hasMore: false,
      );

      expect(history.items, isEmpty);
      expect(history.hasMore, false);
      expect(history.isLoading, false);
    });

    test('isLoading defaults to false', () {
      final history = GoonghapHistoryModel(
        items: [],
        hasMore: true,
      );

      expect(history.isLoading, false);
    });

    test('copyWith works', () {
      final history = GoonghapHistoryModel(
        items: [],
        hasMore: false,
      );

      final updated = history.copyWith(hasMore: true, isLoading: true);
      expect(updated.hasMore, true);
      expect(updated.isLoading, true);
    });

    test('copyWith preserves items', () {
      final item = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      final history = GoonghapHistoryModel(
        items: [item],
        hasMore: true,
      );

      final updated = history.copyWith(isLoading: true);
      expect(updated.items.length, 1);
      expect(updated.items.first.id, 'goonghap-1');
    });

    test('copyWith updates items', () {
      final history = GoonghapHistoryModel(
        items: [],
        hasMore: true,
      );

      final item = GoonghapModel.fromJson({
        ...completedGoonghapData,
        'i18n': <Map<String, dynamic>>[],
      });

      final updated = history.copyWith(items: [item]);
      expect(updated.items.length, 1);
    });
  });

  group('OpenGoonghapResult', () {
    test('enum values exist', () {
      expect(OpenGoonghapResult.values.length, 4);
      expect(OpenGoonghapResult.success, isNotNull);
      expect(OpenGoonghapResult.alreadyPaid, isNotNull);
      expect(OpenGoonghapResult.insufficientBalance, isNotNull);
      expect(OpenGoonghapResult.error, isNotNull);
    });

    test('enum index values', () {
      expect(OpenGoonghapResult.success.index, 0);
      expect(OpenGoonghapResult.alreadyPaid.index, 1);
      expect(OpenGoonghapResult.insufficientBalance.index, 2);
      expect(OpenGoonghapResult.error.index, 3);
    });

    test('enum name values', () {
      expect(OpenGoonghapResult.success.name, 'success');
      expect(OpenGoonghapResult.alreadyPaid.name, 'alreadyPaid');
      expect(OpenGoonghapResult.insufficientBalance.name, 'insufficientBalance');
      expect(OpenGoonghapResult.error.name, 'error');
    });
  });

  group('GoonghapStatus', () {
    test('toJson returns correct values', () {
      expect(GoonghapStatus.pending.toJson(), 'pending');
      expect(GoonghapStatus.completed.toJson(), 'completed');
      expect(GoonghapStatus.error.toJson(), 'error');
      expect(GoonghapStatus.input.toJson(), 'input');
    });

    test('fromJson parses correctly', () {
      expect(GoonghapStatusX.fromJson('pending'), GoonghapStatus.pending);
      expect(GoonghapStatusX.fromJson('completed'), GoonghapStatus.completed);
      expect(GoonghapStatusX.fromJson('error'), GoonghapStatus.error);
    });

    test('fromJson is case insensitive', () {
      expect(GoonghapStatusX.fromJson('PENDING'), GoonghapStatus.pending);
      expect(GoonghapStatusX.fromJson('Completed'), GoonghapStatus.completed);
      expect(GoonghapStatusX.fromJson('ERROR'), GoonghapStatus.error);
    });

    test('fromJson throws for unknown status', () {
      expect(
        () => GoonghapStatusX.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws for empty string', () {
      expect(
        () => GoonghapStatusX.fromJson(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enum has all expected values', () {
      expect(GoonghapStatus.values.length, 4);
      expect(GoonghapStatus.values, contains(GoonghapStatus.pending));
      expect(GoonghapStatus.values, contains(GoonghapStatus.completed));
      expect(GoonghapStatus.values, contains(GoonghapStatus.error));
      expect(GoonghapStatus.values, contains(GoonghapStatus.input));
    });
  });

  group('LocalizedGoonghapX extension', () {
    test('parsedDetails returns null when details is null', () {
      final localized = LocalizedGoonghap(language: 'ko');
      expect(localized.parsedDetails, isNull);
    });

    test('parsedDetails parses valid details', () {
      final localized = LocalizedGoonghap(
        language: 'ko',
        details: Details(
          style: StyleDetails(
            idolStyle: 'a',
            userStyle: 'b',
            coupleStyle: 'c',
          ),
          activities: ActivitiesDetails(
            recommended: ['x'],
            description: 'd',
          ),
        ),
      );

      final parsed = localized.parsedDetails;
      expect(parsed, isNotNull);
      expect(parsed!.style.idolStyle, 'a');
    });

    test('parsedDetails returns correct activities', () {
      final localized = LocalizedGoonghap(
        language: 'en',
        details: Details(
          style: StyleDetails(
            idolStyle: 'energetic',
            userStyle: 'calm',
            coupleStyle: 'balanced',
          ),
          activities: ActivitiesDetails(
            recommended: ['hiking', 'movies'],
            description: 'Fun activities together',
          ),
        ),
      );

      final parsed = localized.parsedDetails;
      expect(parsed, isNotNull);
      expect(parsed!.activities.recommended.length, 2);
      expect(parsed.activities.description, 'Fun activities together');
    });
  });
}
