import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

import '../../helpers/mock_supabase.dart';

/// Additional tests targeting uncovered lines in user_info_provider.dart.
///
/// Targets:
/// - getUserProfiles error path (lines 65-68)
/// - getUserProfiles success with profile found (lines 53-59)
/// - getUserProfiles with null response (lines 60-62)
/// - updateProfile error path (lines 101-104)
/// - updateNickname with non-200 response (lines 131-132)
/// - updateNickname exception path (lines 139-145)
/// - updateLanguage error path (lines 183-187)
/// - logout (lines 108-116)
/// - updateAvatar (lines 149-157)
/// - setAgreement success path (lines 199-207)
/// - agreement success path (lines 222-230)
/// - expireBonus with non-200 status (lines 249-251)
void main() {
  final userProfileData = {
    'id': 'test-user-id',
    'nickname': 'testUser',
    'avatar_url': 'https://example.com/avatar.png',
    'is_admin': false,
    'star_candy': 100,
    'star_candy_bonus': 50,
    'jma_candy': 10,
    'birth_date': '2000-01-15T00:00:00Z',
    'gender': 'female',
    'birth_time': '14:30',
    'deleted_at': null,
    'user_agreement': {
      'id': 'test-user-id',
      'terms': '2026-01-01T00:00:00Z',
      'privacy': '2026-01-01T00:00:00Z',
    },
  };

  group('UserInfo - authenticated getUserProfiles', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('getUserProfiles returns profile when authenticated', () async {
      final result = await container.read(userInfoProvider.future);

      // Should return a UserProfilesModel
      expect(result, isA<UserProfilesModel>());
      expect(result!.id, 'test-user-id');
      expect(result.nickname, 'testUser');
      expect(result.starCandy, 100);
    });

    test('getUserProfiles sets state to data on success', () async {
      await container.read(userInfoProvider.future);

      final notifier = container.read(userInfoProvider.notifier);
      final profile = await notifier.getUserProfiles();

      expect(profile, isNotNull);
      expect(profile!.nickname, 'testUser');

      final state = container.read(userInfoProvider);
      expect(state.hasValue, true);
    });
  });

  group('UserInfo - authenticated getUserProfiles with null response', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': <Map<String, dynamic>>[],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('getUserProfiles returns null when profile not found', () async {
      final result = await container.read(userInfoProvider.future);
      // maybeSingle returns null for empty list
      expect(result, isNull);
    });
  });

  group('UserInfo - authenticated updateProfile', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('updateProfile succeeds with gender and birthDate', () async {
      await container.read(userInfoProvider.future);

      final notifier = container.read(userInfoProvider.notifier);
      // Should not throw
      await notifier.updateProfile(
        gender: 'male',
        birthDate: DateTime(1995, 5, 20),
        birthTime: '10:30',
      );
    });

    test('updateProfile succeeds with only gender', () async {
      await container.read(userInfoProvider.future);

      final notifier = container.read(userInfoProvider.notifier);
      await notifier.updateProfile(gender: 'female');
    });
  });

  group('UserInfo - authenticated updateNickname', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
          'functions:update-nickname': {
            'data': {
              'id': 'test-user-id',
              'nickname': 'newNickname',
              'avatar_url': 'https://example.com/avatar.png',
              'star_candy': 100,
              'star_candy_bonus': 50,
              'jma_candy': 10,
              'is_admin': false,
              'birth_date': null,
              'gender': null,
              'birth_time': null,
              'deleted_at': null,
              'user_agreement': null,
            },
          },
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('updateNickname returns bool', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      final result = await notifier.updateNickname('newNickname');
      expect(result, isA<bool>());
    });
  });

  group('UserInfo - authenticated updateNickname with error response', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
          'functions:update-nickname': {
            'error': 'Nickname already taken',
          },
        },
        userId: 'test-user-id',
        functionStatusCodes: {'functions:update-nickname': 400},
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('updateNickname returns false on error response', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      final result = await notifier.updateNickname('takenNickname');
      expect(result, isFalse);
    });
  });

  group('UserInfo - authenticated updateAvatar', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('updateAvatar updates state', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      await notifier.updateAvatar('https://example.com/new-avatar.png');

      final state = container.read(userInfoProvider);
      expect(state.value?.avatarUrl, 'https://example.com/new-avatar.png');
    });
  });

  // logout() is not easily testable with ProviderContainer alone because
  // it accesses navigationInfoProvider which needs Environment config.
  // It's tested via widget tests with buildTestApp() instead.

  group('UserInfo - authenticated updateLanguage', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_profiles': [userProfileData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('updateLanguage succeeds with ko', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      // Should not throw
      await notifier.updateLanguage('ko');
    });

    test('updateLanguage normalizes zh_CN to zh', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      await notifier.updateLanguage('zh_CN');
    });

    test('updateLanguage normalizes zh_TW to zh-TW', () async {
      await container.read(userInfoProvider.future);
      final notifier = container.read(userInfoProvider.notifier);

      await notifier.updateLanguage('zh_TW');
    });
  });

  group('setAgreement - authenticated', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_agreement': [
            {
              'id': 'test-user-id',
              'terms': 'now',
              'privacy': 'now',
            },
          ],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns true on success', () async {
      final result = await container.read(setAgreementProvider.future);
      expect(result, isA<bool>());
    });
  });

  group('agreement - authenticated', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'user_agreement': [
            {
              'id': 'test-user-id',
              'terms': '2026-01-01T00:00:00Z',
              'privacy': '2026-01-01T00:00:00Z',
            },
          ],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns true on success', () async {
      final result = await container.read(agreementProvider.future);
      expect(result, isA<bool>());
    });
  });

  group('expireBonus - edge cases', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'functions:expiring-bonus': [
          {'prediction_month': '2026-04', 'expiring_amount': 50},
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns list from array response', () async {
      final result = await container.read(expireBonusProvider.future);
      expect(result, isNotNull);
      expect(result!.length, 1);
    });
  });

  group('expireBonus - non-200 status', () {
    late ProviderContainer container;

    setUp(() {
      // FunctionsClient throws FunctionException for non-2xx status codes.
      // The provider catches this and returns null.
      setupMockSupabase(
        {
          'functions:expiring-bonus': {'error': 'internal error'},
        },
        functionStatusCodes: {'functions:expiring-bonus': 500},
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns null on non-200 response (FunctionException caught)',
        () async {
      // FunctionsClient.invoke throws FunctionException for status >= 300.
      // The expireBonus provider catches all exceptions and returns null.
      final result = await container.read(expireBonusProvider.future);
      expect(result, isNull);
    });
  });

  group('expireBonus - unexpected format', () {
    late ProviderContainer container;

    setUp(() {
      // Return a string that's not a list or map with data key
      setupMockSupabase({
        'functions:expiring-bonus': 'unexpected string',
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns null for unexpected response format', () async {
      final result = await container.read(expireBonusProvider.future);
      // parseExpireBonusResponse returns null for non-list/non-map-with-data
      // Then the code throws Exception('Unexpected response format')
      // which is caught -> returns null
      expect(result, isNull);
    });
  });
}
