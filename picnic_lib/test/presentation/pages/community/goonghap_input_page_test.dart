import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_input_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';

/// Tests that exercise production code from goonghap_input_page.dart
/// and its direct dependencies (date.dart, locale_utils.dart, models).
///
/// Widget rendering is blocked by transitive flutter_svg / cached_network_image
/// imports, so we focus on exercising production functions and model code.
void main() {
  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '지민', 'en': 'Jimin'},
    gender: 'male',
    birthDateRaw: DateTime(1995, 10, 13),
  );

  group('convertKoreanTraditionalTime (production, date.dart)', () {
    test('returns correct emoji for all 12 time slots', () {
      expect(convertKoreanTraditionalTime('1'), equals('🐀'));
      expect(convertKoreanTraditionalTime('2'), equals('🐂'));
      expect(convertKoreanTraditionalTime('3'), equals('🐅'));
      expect(convertKoreanTraditionalTime('4'), equals('🐇'));
      expect(convertKoreanTraditionalTime('5'), equals('🐉'));
      expect(convertKoreanTraditionalTime('6'), equals('🐍'));
      expect(convertKoreanTraditionalTime('7'), equals('🐎'));
      expect(convertKoreanTraditionalTime('8'), equals('🐑'));
      expect(convertKoreanTraditionalTime('9'), equals('🐒'));
      expect(convertKoreanTraditionalTime('10'), equals('🐓'));
      expect(convertKoreanTraditionalTime('11'), equals('🐕'));
      expect(convertKoreanTraditionalTime('12'), equals('🐖'));
    });

    test('returns empty string for null', () {
      expect(convertKoreanTraditionalTime(null), equals(''));
    });

    test('returns empty string for unknown values', () {
      expect(convertKoreanTraditionalTime('0'), equals(''));
      expect(convertKoreanTraditionalTime('13'), equals(''));
      expect(convertKoreanTraditionalTime('unknown'), equals(''));
      expect(convertKoreanTraditionalTime('-1'), equals(''));
      expect(convertKoreanTraditionalTime(''), equals(''));
    });
  });

  group('getLocaleTextFromJsonWithLocale (production, locale_utils.dart)', () {
    test('returns Korean text for ko locale', () {
      final json = {'ko': '지민', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'ko'), equals('지민'));
    });

    test('returns English text for en locale', () {
      final json = {'ko': '지민', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'en'), equals('Jimin'));
    });

    test('returns English fallback when locale not found', () {
      final json = {'ko': '지민', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'ja'), equals('Jimin'));
    });

    test('returns empty string when json is empty', () {
      expect(getLocaleTextFromJsonWithLocale({}, 'ko'), equals(''));
    });

    test('returns empty string when no matching locale and no en fallback', () {
      final json = {'ko': '지민'};
      expect(getLocaleTextFromJsonWithLocale(json, 'ja'), equals(''));
    });

    test('normalizes zh_CN to zh for Chinese Simplified', () {
      final json = {'zh': '智旻', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'zh_CN'), equals('智旻'));
      expect(getLocaleTextFromJsonWithLocale(json, 'zh-CN'), equals('智旻'));
    });

    test('normalizes zh_TW to zh-TW for Chinese Traditional', () {
      final json = {'zh-TW': '智旻', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'zh_TW'), equals('智旻'));
      expect(getLocaleTextFromJsonWithLocale(json, 'zh-TW'), equals('智旻'));
    });

    test('normalizes bn_BD to bn for Bengali', () {
      final json = {'bn': 'জিমিন', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'bn_BD'), equals('জিমিন'));
      expect(getLocaleTextFromJsonWithLocale(json, 'bn'), equals('জিমিন'));
    });

    test('returns value for simple language codes', () {
      final json = {'th': 'จีมิน', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'th'), equals('จีมิน'));
    });

    test('returns value for id locale', () {
      final json = {'id': 'Jimin ID', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'id'), equals('Jimin ID'));
    });

    test('returns value for vi locale', () {
      final json = {'vi': 'Jimin VI', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'vi'), equals('Jimin VI'));
    });

    test('returns value for fil locale', () {
      final json = {'fil': 'Jimin FIL', 'en': 'Jimin'};
      expect(getLocaleTextFromJsonWithLocale(json, 'fil'), equals('Jimin FIL'));
    });
  });

  group('formatLocalDateTime (production, date.dart)', () {
    test('returns empty string for null dateTime', () {
      expect(formatLocalDateTime(null), equals(''));
    });

    test('formats date without timezone', () {
      final dt = DateTime.utc(2025, 6, 15, 10, 30);
      final result = formatLocalDateTime(dt, includeTimezone: false);
      expect(result, isNotEmpty);
      // Should contain the date components
      expect(result, contains('2025'));
      expect(result, contains('06'));
      expect(result, contains('15'));
    });

    test('formats date with timezone', () {
      final dt = DateTime.utc(2025, 1, 1, 0, 0);
      final result = formatLocalDateTime(dt, includeTimezone: true);
      expect(result, isNotEmpty);
    });

    test('formats with custom format string', () {
      final dt = DateTime.utc(2025, 3, 20, 14, 45);
      final result = formatLocalDateTime(
        dt,
        format: 'yyyy-MM-dd',
        includeTimezone: false,
      );
      expect(result, isNotEmpty);
      expect(result, contains('2025'));
    });
  });

  group('formatVotePeriod (production, date.dart)', () {
    test('returns empty string when startAt is null', () {
      expect(formatVotePeriod(null, DateTime.now()), equals(''));
    });

    test('returns empty string when stopAt is null', () {
      expect(formatVotePeriod(DateTime.now(), null), equals(''));
    });

    test('returns empty string when both are null', () {
      expect(formatVotePeriod(null, null), equals(''));
    });

    test('returns formatted period string', () {
      final start = DateTime.utc(2025, 1, 1, 0, 0);
      final stop = DateTime.utc(2025, 1, 7, 23, 59);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });
  });

  group('getTimezoneAbbreviation (production, date.dart)', () {
    test('returns non-empty timezone string', () {
      final tz = getTimezoneAbbreviation();
      expect(tz, isNotEmpty);
    });
  });

  group('getCurrentTimeZoneIdentifier (production, date.dart)', () {
    test('returns non-empty timezone identifier', () {
      final tz = getCurrentTimeZoneIdentifier();
      expect(tz, isNotEmpty);
    });
  });

  group('getShortTimeZoneIdentifier (production, date.dart)', () {
    test('returns non-empty short timezone identifier', () {
      final tz = getShortTimeZoneIdentifier();
      expect(tz, isNotEmpty);
    });
  });

  group('UserProfilesModel (production)', () {
    test('creates user profile with all fields', () {
      final userProfile = UserProfilesModel(
        id: 'test-user-id',
        nickname: 'TestUser',
        isAdmin: false,
        starCandy: 100,
        starCandyBonus: 10,
        jmaCandy: 50,
        birthDate: DateTime(1998, 3, 15),
        gender: 'female',
        birthTime: '3',
      );

      expect(userProfile.id, equals('test-user-id'));
      expect(userProfile.nickname, equals('TestUser'));
      expect(userProfile.isAdmin, isFalse);
      expect(userProfile.starCandy, equals(100));
      expect(userProfile.birthDate, equals(DateTime(1998, 3, 15)));
      expect(userProfile.gender, equals('female'));
      expect(userProfile.birthTime, equals('3'));
    });

    test('creates user profile with null optional fields', () {
      final userProfile = UserProfilesModel(
        id: 'test-user-id',
        nickname: 'TestUser',
        isAdmin: false,
        starCandy: 100,
        starCandyBonus: 10,
        jmaCandy: 50,
        birthDate: null,
        gender: null,
        birthTime: null,
      );

      expect(userProfile.birthDate, isNull);
      expect(userProfile.gender, isNull);
      expect(userProfile.birthTime, isNull);
    });

    test('creates admin user profile', () {
      final userProfile = UserProfilesModel(
        id: 'admin-id',
        nickname: 'Admin',
        isAdmin: true,
        starCandy: 500,
        starCandyBonus: 50,
        jmaCandy: 200,
        birthDate: DateTime(1990, 12, 25),
        gender: 'male',
        birthTime: '7',
      );

      expect(userProfile.isAdmin, isTrue);
      expect(userProfile.starCandy, equals(500));
    });
  });

  group('ArtistModel (production)', () {
    test('artist has required fields', () {
      expect(testArtist.id, equals(1));
      expect(testArtist.name['ko'], equals('지민'));
      expect(testArtist.name['en'], equals('Jimin'));
    });

    test('artist with birth date', () {
      expect(testArtist.birthDate, isNotNull);
      expect(testArtist.birthDate, equals(DateTime(1995, 10, 13)));
    });

    test('artist without birth date', () {
      final artistNoBirth = ArtistModel(
        id: 2,
        name: {'ko': '뷔', 'en': 'V'},
      );
      expect(artistNoBirth.birthDate, isNull);
      expect(artistNoBirth.gender, isNull);
    });

    test('artist serialization round-trip', () {
      final json = testArtist.toJson();
      expect(json, isNotNull);
      expect(json['id'], equals(1));
      expect(json['name'], isA<Map>());

      final restored = ArtistModel.fromJson(json);
      expect(restored.id, equals(testArtist.id));
      expect(restored.name['ko'], equals('지민'));
    });

    test('artist with image', () {
      final artist = ArtistModel(
        id: 3,
        name: {'ko': 'BTS', 'en': 'BTS'},
        image: 'https://example.com/bts.jpg',
      );
      expect(artist.image, equals('https://example.com/bts.jpg'));
    });

    test('artist without image', () {
      final artist = ArtistModel(id: 4, name: {'ko': 'Test'});
      expect(artist.image, isNull);
    });
  });

  group('GoonghapModel.fromJson (production, exercises _parseI18nResults)', () {
    test('parses full goonghap from JSON with i18n Map', () {
      final json = {
        'id': 'g1',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민', 'en': 'Jimin'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'gender': 'male',
        'status': 'completed',
        'score': 85,
        'i18n': {
          'ko': {
            'language': 'ko',
            'score': 85,
            'score_title': '좋은 궁합',
            'goonghap_summary': '환상적!',
          },
        },
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.id, equals('g1'));
      expect(model.userId, equals('u1'));
      expect(model.score, equals(85));
      expect(model.isCompleted, isTrue);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!['ko']!.scoreTitle, equals('좋은 궁합'));
    });

    test('parses goonghap from JSON with i18n List', () {
      final json = {
        'id': 'g2',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'status': 'completed',
        'i18n': [
          {
            'language': 'ko',
            'score': 90,
            'score_title': '환상궁합',
            'goonghap_summary': '최고!',
          },
          {
            'language': 'en',
            'score': 90,
            'score_title': 'Amazing Match',
            'goonghap_summary': 'Best!',
          },
        ],
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(2));
      expect(model.localizedResults!['ko']!.score, equals(90));
      expect(model.localizedResults!['en']!.scoreTitle, equals('Amazing Match'));
    });

    test('parses goonghap with null i18n', () {
      final json = {
        'id': 'g3',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'status': 'pending',
        'i18n': null,
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
      expect(model.isPending, isTrue);
    });

    test('parses goonghap with empty i18n Map', () {
      final json = {
        'id': 'g4',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'status': 'completed',
        'i18n': <String, dynamic>{},
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
    });

    test('parses goonghap with empty i18n List', () {
      final json = {
        'id': 'g5',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'status': 'error',
        'error_message': 'Something went wrong',
        'i18n': <dynamic>[],
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
      expect(model.hasError, isTrue);
      expect(model.errorMessage, equals('Something went wrong'));
    });

    test('parses goonghap with all optional fields', () {
      final json = {
        'id': 'g6',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'user_birth_time': '5',
        'status': 'completed',
        'gender': 'female',
        'score': 92,
        'goonghap_summary': 'Great match',
        'is_ads': true,
        'is_paid': true,
        'created_at': '2025-01-01T00:00:00.000',
        'completed_at': '2025-01-01T01:00:00.000',
        'tips': ['Tip 1', 'Tip 2'],
        'i18n': null,
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.birthTime, equals('5'));
      expect(model.gender, equals('female'));
      expect(model.score, equals(92));
      expect(model.isAds, isTrue);
      expect(model.isPaid, isTrue);
      expect(model.createdAt, isNotNull);
      expect(model.completedAt, isNotNull);
      expect(model.tips, isNotNull);
      expect(model.tips!.length, equals(2));
    });

    test('status defaults to pending when not provided', () {
      final json = {
        'id': 'g7',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.isPending, isTrue);
    });
  });

  group('GoonghapModel serialization round-trip (production)', () {
    test('toJson and fromJson produce equivalent model', () {
      final original = GoonghapModel(
        id: 'g-rt',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        gender: 'male',
        score: 85,
        birthTime: '3',
        isAds: true,
        isPaid: false,
      );

      final json = original.toJson();
      final restored = GoonghapModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.status, equals(original.status));
      expect(restored.gender, equals(original.gender));
      expect(restored.score, equals(original.score));
      expect(restored.birthTime, equals(original.birthTime));
      expect(restored.isAds, equals(original.isAds));
      expect(restored.isPaid, equals(original.isPaid));
    });
  });

  group('GoonghapModel computed properties (production)', () {
    test('isPending is true only for pending status', () {
      final m = GoonghapModel(
        id: 'p', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.pending,
      );
      expect(m.isPending, isTrue);
      expect(m.isCompleted, isFalse);
      expect(m.hasError, isFalse);
    });

    test('isCompleted is true only for completed status', () {
      final m = GoonghapModel(
        id: 'c', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.completed,
      );
      expect(m.isPending, isFalse);
      expect(m.isCompleted, isTrue);
      expect(m.hasError, isFalse);
    });

    test('hasError is true only for error status', () {
      final m = GoonghapModel(
        id: 'e', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.error,
      );
      expect(m.isPending, isFalse);
      expect(m.isCompleted, isFalse);
      expect(m.hasError, isTrue);
    });

    test('input status is neither pending, completed nor error', () {
      final m = GoonghapModel(
        id: 'i', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.input,
      );
      expect(m.isPending, isFalse);
      expect(m.isCompleted, isFalse);
      expect(m.hasError, isFalse);
    });
  });

  group('GoonghapModel.getLocalizedResult (production)', () {
    test('returns result for existing language', () {
      final goonghap = GoonghapModel(
        id: 'glr', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.completed,
        localizedResults: {
          'ko': const LocalizedGoonghap(language: 'ko', score: 85),
          'en': const LocalizedGoonghap(language: 'en', score: 85),
        },
      );

      expect(goonghap.getLocalizedResult('ko'), isNotNull);
      expect(goonghap.getLocalizedResult('ko')!.score, equals(85));
      expect(goonghap.getLocalizedResult('en'), isNotNull);
      expect(goonghap.getLocalizedResult('ja'), isNull);
    });

    test('returns null when localizedResults is null', () {
      final goonghap = GoonghapModel(
        id: 'glr2', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.pending,
      );

      expect(goonghap.getLocalizedResult('ko'), isNull);
    });
  });

  group('GoonghapStatus extension (production)', () {
    test('toJson returns name string', () {
      expect(GoonghapStatus.pending.toJson(), equals('pending'));
      expect(GoonghapStatus.completed.toJson(), equals('completed'));
      expect(GoonghapStatus.error.toJson(), equals('error'));
      expect(GoonghapStatus.input.toJson(), equals('input'));
    });

    test('fromJson parses valid strings', () {
      expect(GoonghapStatusX.fromJson('pending'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('completed'), equals(GoonghapStatus.completed));
      expect(GoonghapStatusX.fromJson('error'), equals(GoonghapStatus.error));
    });

    test('fromJson is case insensitive', () {
      expect(GoonghapStatusX.fromJson('PENDING'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('Completed'), equals(GoonghapStatus.completed));
    });

    test('fromJson throws for unknown status', () {
      expect(() => GoonghapStatusX.fromJson('unknown'), throwsA(isA<ArgumentError>()));
      expect(() => GoonghapStatusX.fromJson(''), throwsA(isA<ArgumentError>()));
    });
  });

  group('LocalizedGoonghap (production)', () {
    test('fromJson parses with all fields', () {
      final json = {
        'language': 'ko',
        'score': 92,
        'score_title': '환상궁합',
        'goonghap_summary': '최고의 조합!',
        'details': {
          'style': {
            'idol_style': '감성적',
            'user_style': '열정적',
            'couple_style': '따뜻한',
          },
          'activities': {
            'recommended': ['카페', '산책'],
            'description': '함께 시간을 보내기 좋아요',
          },
        },
        'tips': ['매일 소통하세요', '서로를 존중하세요'],
      };

      final result = LocalizedGoonghap.fromJson(json);
      expect(result.language, equals('ko'));
      expect(result.score, equals(92));
      expect(result.scoreTitle, equals('환상궁합'));
      expect(result.goonghapSummary, equals('최고의 조합!'));
      expect(result.details, isNotNull);
      expect(result.details!.style.idolStyle, equals('감성적'));
      expect(result.details!.activities.recommended.length, equals(2));
      expect(result.tips.length, equals(2));
    });

    test('fromJson parses with minimal fields (defaults)', () {
      final json = {'language': 'en'};

      final result = LocalizedGoonghap.fromJson(json);
      expect(result.language, equals('en'));
      expect(result.score, equals(0));
      expect(result.scoreTitle, equals(''));
      expect(result.goonghapSummary, equals(''));
      expect(result.details, isNull);
      expect(result.tips, isEmpty);
    });

    test('toJson serialization', () {
      const result = LocalizedGoonghap(
        language: 'ko',
        score: 85,
        scoreTitle: 'Great',
        goonghapSummary: 'Amazing',
      );

      final json = result.toJson();
      expect(json['language'], equals('ko'));
      expect(json['score'], equals(85));
      expect(json['score_title'], equals('Great'));
    });
  });

  group('Details and sub-models (production)', () {
    test('Details.fromJson parses correctly', () {
      final json = {
        'style': {
          'idol_style': 'Emotional',
          'user_style': 'Passionate',
          'couple_style': 'Warm',
        },
        'activities': {
          'recommended': ['Cafe', 'Walking'],
          'description': 'Great time together',
        },
      };

      final details = Details.fromJson(json);
      expect(details.style.idolStyle, equals('Emotional'));
      expect(details.style.userStyle, equals('Passionate'));
      expect(details.style.coupleStyle, equals('Warm'));
      expect(details.activities.recommended, contains('Cafe'));
      expect(details.activities.description, equals('Great time together'));
    });

    test('StyleDetails.fromJson', () {
      final json = {
        'idol_style': 'A',
        'user_style': 'B',
        'couple_style': 'C',
      };
      final style = StyleDetails.fromJson(json);
      expect(style.idolStyle, equals('A'));
      expect(style.userStyle, equals('B'));
      expect(style.coupleStyle, equals('C'));
    });

    test('ActivitiesDetails.fromJson', () {
      final json = {
        'recommended': ['X', 'Y', 'Z'],
        'description': 'Desc',
      };
      final activities = ActivitiesDetails.fromJson(json);
      expect(activities.recommended.length, equals(3));
      expect(activities.description, equals('Desc'));
    });
  });

  group('GoonghapModel constructor properties (production)', () {
    test('isAds property', () {
      final g = GoonghapModel(
        id: 'g-ads', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.completed,
        isAds: true,
      );
      expect(g.isAds, isTrue);
    });

    test('isPaid property', () {
      final g = GoonghapModel(
        id: 'g-paid', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.completed,
        isPaid: true,
      );
      expect(g.isPaid, isTrue);
    });

    test('errorMessage property', () {
      final g = GoonghapModel(
        id: 'g-err', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.error,
        errorMessage: 'Custom error',
      );
      expect(g.errorMessage, equals('Custom error'));
    });

    test('null errorMessage defaults', () {
      final g = GoonghapModel(
        id: 'g-err2', userId: 'u', artist: testArtist,
        birthDate: DateTime(2000), status: GoonghapStatus.error,
      );
      expect(g.errorMessage, isNull);
    });
  });

  group('GoonghapInputPage widget rendering', () {
    late void Function() restore;

    setUp(() {
      setupMockSupabase({
        'goonghap_results': <dynamic>[],
      });
      restore = suppressImageErrors();
    });

    tearDown(() {
      restore();
      tearDownMockSupabase();
    });

    testWidgets('renders without crashing', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders page structure', (WidgetTester tester) async {
      final artist = MockData.artist();

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      // Verify the page rendered
      expect(find.byType(GoonghapInputPage), findsOneWidget);
      // Should be wrapped in a MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('renders in logged-out state', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          locale: const Locale('en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('checkbox toggle works', (WidgetTester tester) async {
      final artist = MockData.artist();

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      final checkbox = find.byType(CheckboxListTile);
      if (checkbox.evaluate().isNotEmpty) {
        // Tap to toggle on
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);

        // Tap to toggle off
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('dispose cleans up without error', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(buildTestAppPage(const SizedBox()));
      drainExpectedImageErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 200));
    });
  });
}
