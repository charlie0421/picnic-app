import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

void main() {
  // -- Helper JSON builders --

  Map<String, dynamic> makeArtistJson({int id = 1}) => {
        'id': id,
        'name': {'ko': '정국', 'en': 'Jungkook'},
        'gender': 'male',
      };

  Map<String, dynamic> makeStyleJson() => {
        'idol_style': 'cool',
        'user_style': 'warm',
        'couple_style': 'balanced',
      };

  Map<String, dynamic> makeActivitiesJson() => {
        'recommended': ['travel', 'cooking'],
        'description': 'Great together',
      };

  Map<String, dynamic> makeDetailsJson() => {
        'style': makeStyleJson(),
        'activities': makeActivitiesJson(),
      };

  Map<String, dynamic> makeLocalizedGoonghapJson({
    String language = 'ko',
    int score = 85,
  }) =>
      {
        'language': language,
        'score': score,
        'score_title': 'Great',
        'goonghap_summary': 'Summary in $language',
        'details': makeDetailsJson(),
        'tips': ['tip1', 'tip2'],
      };

  Map<String, dynamic> makeGoonghapJson({
    String status = 'completed',
    dynamic i18n,
  }) =>
      {
        'id': 'g-123',
        'user_id': 'u-abc',
        'artist': makeArtistJson(),
        'user_birth_date': '2000-01-15T00:00:00.000Z',
        'user_birth_time': '14:30',
        'status': status,
        'gender': 'female',
        'score': 90,
        'goonghap_summary': 'Great match',
        'details': makeDetailsJson(),
        'tips': ['Be kind'],
        'created_at': '2024-01-01T00:00:00.000Z',
        'completed_at': '2024-01-01T00:05:00.000Z',
        'is_ads': false,
        'is_paid': true,
        if (i18n != null) 'i18n': i18n,
      };

  // ===== GoonghapStatus enum =====

  group('GoonghapStatus', () {
    group('toJson()', () {
      test('returns "pending" for pending', () {
        expect(GoonghapStatus.pending.toJson(), 'pending');
      });

      test('returns "completed" for completed', () {
        expect(GoonghapStatus.completed.toJson(), 'completed');
      });

      test('returns "error" for error', () {
        expect(GoonghapStatus.error.toJson(), 'error');
      });

      test('returns "input" for input', () {
        expect(GoonghapStatus.input.toJson(), 'input');
      });
    });

    group('fromJson()', () {
      test('parses "pending"', () {
        expect(GoonghapStatusX.fromJson('pending'), GoonghapStatus.pending);
      });

      test('parses "completed"', () {
        expect(
            GoonghapStatusX.fromJson('completed'), GoonghapStatus.completed);
      });

      test('parses "error"', () {
        expect(GoonghapStatusX.fromJson('error'), GoonghapStatus.error);
      });

      test('is case-insensitive', () {
        expect(GoonghapStatusX.fromJson('PENDING'), GoonghapStatus.pending);
        expect(
            GoonghapStatusX.fromJson('Completed'), GoonghapStatus.completed);
        expect(GoonghapStatusX.fromJson('ERROR'), GoonghapStatus.error);
      });

      test('throws ArgumentError for unknown value', () {
        expect(() => GoonghapStatusX.fromJson('unknown'), throwsArgumentError);
      });

      test('throws ArgumentError for empty string', () {
        expect(() => GoonghapStatusX.fromJson(''), throwsArgumentError);
      });
    });
  });

  // ===== GoonghapModel.fromJson (also tests _parseI18nResults indirectly) =====

  group('GoonghapModel.fromJson', () {
    test('parses all fields correctly', () {
      final json = makeGoonghapJson();
      final model = GoonghapModel.fromJson(json);

      expect(model.id, 'g-123');
      expect(model.userId, 'u-abc');
      expect(model.artist.id, 1);
      expect(model.birthDate, DateTime.parse('2000-01-15T00:00:00.000Z'));
      expect(model.birthTime, '14:30');
      expect(model.status, GoonghapStatus.completed);
      expect(model.gender, 'female');
      expect(model.score, 90);
      expect(model.goonghapSummary, 'Great match');
      expect(model.details, isNotNull);
      expect(model.tips, ['Be kind']);
      expect(model.createdAt, isNotNull);
      expect(model.completedAt, isNotNull);
      expect(model.isAds, false);
      expect(model.isPaid, true);
    });

    test('defaults status to pending when absent', () {
      final json = makeGoonghapJson()..remove('status');
      final model = GoonghapModel.fromJson(json);
      expect(model.status, GoonghapStatus.pending);
    });

    test('defaults id to empty string when absent', () {
      final json = makeGoonghapJson()..remove('id');
      final model = GoonghapModel.fromJson(json);
      expect(model.id, '');
    });

    test('nullable fields default to null', () {
      final json = <String, dynamic>{
        'user_id': 'u1',
        'artist': makeArtistJson(),
        'user_birth_date': '2000-01-01T00:00:00.000Z',
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.birthTime, isNull);
      expect(model.gender, isNull);
      expect(model.errorMessage, isNull);
      expect(model.isLoading, isNull);
      expect(model.score, isNull);
      expect(model.goonghapSummary, isNull);
      expect(model.details, isNull);
      expect(model.tips, isNull);
      expect(model.createdAt, isNull);
      expect(model.completedAt, isNull);
      expect(model.localizedResults, isNull);
      expect(model.isAds, isNull);
      expect(model.isPaid, isNull);
    });

    group('_parseI18nResults via i18n field', () {
      test('parses i18n as Map', () {
        final json = makeGoonghapJson(i18n: {
          'ko': makeLocalizedGoonghapJson(language: 'ko', score: 85),
          'en': makeLocalizedGoonghapJson(language: 'en', score: 70),
        });
        final model = GoonghapModel.fromJson(json);

        expect(model.localizedResults, isNotNull);
        expect(model.localizedResults!.length, 2);
        expect(model.localizedResults!['ko']!.score, 85);
        expect(model.localizedResults!['en']!.score, 70);
      });

      test('parses i18n as List', () {
        final json = makeGoonghapJson(i18n: [
          makeLocalizedGoonghapJson(language: 'ko', score: 90),
          makeLocalizedGoonghapJson(language: 'ja', score: 60),
        ]);
        final model = GoonghapModel.fromJson(json);

        expect(model.localizedResults, isNotNull);
        expect(model.localizedResults!.length, 2);
        expect(model.localizedResults!['ko']!.score, 90);
        expect(model.localizedResults!['ja']!.score, 60);
      });

      test('returns null when i18n is null', () {
        final json = makeGoonghapJson();
        // No i18n key at all
        final model = GoonghapModel.fromJson(json);
        expect(model.localizedResults, isNull);
      });

      test('returns null when i18n Map is empty', () {
        final json = makeGoonghapJson(i18n: <String, dynamic>{});
        final model = GoonghapModel.fromJson(json);
        // Empty map parsed -> results map is empty -> returns null
        expect(model.localizedResults, isNull);
      });

      test('returns null when i18n List is empty', () {
        final json = makeGoonghapJson(i18n: []);
        final model = GoonghapModel.fromJson(json);
        expect(model.localizedResults, isNull);
      });

      test('skips List items without language field', () {
        final json = makeGoonghapJson(i18n: [
          {'score': 80}, // no language
          makeLocalizedGoonghapJson(language: 'ko'),
        ]);
        final model = GoonghapModel.fromJson(json);
        expect(model.localizedResults, isNotNull);
        expect(model.localizedResults!.length, 1);
        expect(model.localizedResults!.containsKey('ko'), isTrue);
      });

      test('skips Map entries with non-Map values', () {
        final json = makeGoonghapJson(i18n: {
          'ko': makeLocalizedGoonghapJson(language: 'ko'),
          'bad': 'not a map',
        });
        final model = GoonghapModel.fromJson(json);
        expect(model.localizedResults, isNotNull);
        expect(model.localizedResults!.length, 1);
      });

      test('skips List items that are not Map<String, dynamic>', () {
        final json = makeGoonghapJson(i18n: [
          'invalid',
          42,
          makeLocalizedGoonghapJson(language: 'en'),
        ]);
        final model = GoonghapModel.fromJson(json);
        expect(model.localizedResults, isNotNull);
        expect(model.localizedResults!.length, 1);
        expect(model.localizedResults!.containsKey('en'), isTrue);
      });
    });
  });

  // ===== GoonghapModel computed getters =====

  group('GoonghapModel getters', () {
    test('isPending is true only for pending status', () {
      final model = GoonghapModel(
        userId: 'u1',
        artist: ArtistModel.fromJson(makeArtistJson()),
        birthDate: DateTime(2000),
        status: GoonghapStatus.pending,
      );
      expect(model.isPending, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.hasError, isFalse);
    });

    test('isCompleted is true only for completed status', () {
      final model = GoonghapModel(
        userId: 'u1',
        artist: ArtistModel.fromJson(makeArtistJson()),
        birthDate: DateTime(2000),
        status: GoonghapStatus.completed,
      );
      expect(model.isPending, isFalse);
      expect(model.isCompleted, isTrue);
      expect(model.hasError, isFalse);
    });

    test('hasError is true only for error status', () {
      final model = GoonghapModel(
        userId: 'u1',
        artist: ArtistModel.fromJson(makeArtistJson()),
        birthDate: DateTime(2000),
        status: GoonghapStatus.error,
      );
      expect(model.isPending, isFalse);
      expect(model.isCompleted, isFalse);
      expect(model.hasError, isTrue);
    });

    test('getLocalizedResult returns correct localization', () {
      final ko = LocalizedGoonghap(language: 'ko', score: 80);
      final en = LocalizedGoonghap(language: 'en', score: 75);
      final model = GoonghapModel(
        userId: 'u1',
        artist: ArtistModel.fromJson(makeArtistJson()),
        birthDate: DateTime(2000),
        localizedResults: {'ko': ko, 'en': en},
      );
      expect(model.getLocalizedResult('ko')?.score, 80);
      expect(model.getLocalizedResult('en')?.score, 75);
      expect(model.getLocalizedResult('ja'), isNull);
    });

    test('getLocalizedResult returns null when localizedResults is null', () {
      final model = GoonghapModel(
        userId: 'u1',
        artist: ArtistModel.fromJson(makeArtistJson()),
        birthDate: DateTime(2000),
      );
      expect(model.getLocalizedResult('ko'), isNull);
    });
  });

  // ===== LocalizedGoonghap.fromJson =====

  group('LocalizedGoonghap.fromJson', () {
    test('parses all fields', () {
      final json = makeLocalizedGoonghapJson(language: 'ko', score: 95);
      final result = LocalizedGoonghap.fromJson(json);

      expect(result.language, 'ko');
      expect(result.score, 95);
      expect(result.scoreTitle, 'Great');
      expect(result.goonghapSummary, 'Summary in ko');
      expect(result.details, isNotNull);
      expect(result.tips, ['tip1', 'tip2']);
    });

    test('uses defaults for optional fields', () {
      final json = {'language': 'ja'};
      final result = LocalizedGoonghap.fromJson(json);

      expect(result.language, 'ja');
      expect(result.score, 0);
      expect(result.scoreTitle, '');
      expect(result.goonghapSummary, '');
      expect(result.details, isNull);
      expect(result.tips, isEmpty);
    });
  });

  // ===== Details.fromJson =====

  group('Details.fromJson', () {
    test('parses style and activities', () {
      final json = makeDetailsJson();
      final details = Details.fromJson(json);

      expect(details.style.idolStyle, 'cool');
      expect(details.style.userStyle, 'warm');
      expect(details.style.coupleStyle, 'balanced');
      expect(details.activities.recommended, ['travel', 'cooking']);
      expect(details.activities.description, 'Great together');
    });
  });

  // ===== StyleDetails.fromJson =====

  group('StyleDetails.fromJson', () {
    test('parses JSON key names correctly', () {
      final json = {
        'idol_style': 'charismatic',
        'user_style': 'gentle',
        'couple_style': 'dynamic duo',
      };
      final style = StyleDetails.fromJson(json);

      expect(style.idolStyle, 'charismatic');
      expect(style.userStyle, 'gentle');
      expect(style.coupleStyle, 'dynamic duo');
    });
  });

  // ===== ActivitiesDetails.fromJson =====

  group('ActivitiesDetails.fromJson', () {
    test('parses recommended list and description', () {
      final json = {
        'recommended': ['hiking', 'movies', 'cafe'],
        'description': 'Fun activities for you two',
      };
      final activities = ActivitiesDetails.fromJson(json);

      expect(activities.recommended, hasLength(3));
      expect(activities.recommended.first, 'hiking');
      expect(activities.description, 'Fun activities for you two');
    });

    test('parses empty recommended list', () {
      final json = {
        'recommended': <String>[],
        'description': 'None yet',
      };
      final activities = ActivitiesDetails.fromJson(json);
      expect(activities.recommended, isEmpty);
    });
  });

  // ===== LocalizedGoonghapX.parsedDetails extension =====

  group('LocalizedGoonghapX.parsedDetails', () {
    test('returns Details when details is present', () {
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
      expect(parsed.activities.description, 'd');
    });

    test('returns null when details is null', () {
      const localized = LocalizedGoonghap(language: 'ko');
      // details is null -> toJson returns {} -> fromJson on empty map will fail
      // The extension catches the error and returns null
      final parsed = localized.parsedDetails;
      expect(parsed, isNull);
    });
  });

  // ===== Roundtrip serialization =====

  group('Roundtrip serialization', () {
    test('GoonghapModel toJson/fromJson roundtrip', () {
      final json = makeGoonghapJson(i18n: {
        'ko': makeLocalizedGoonghapJson(language: 'ko'),
      });
      final model = GoonghapModel.fromJson(json);
      final reJson = model.toJson();
      final model2 = GoonghapModel.fromJson(reJson);

      expect(model2.id, model.id);
      expect(model2.userId, model.userId);
      expect(model2.status, model.status);
      expect(model2.score, model.score);
      expect(model2.localizedResults?['ko']?.score,
          model.localizedResults?['ko']?.score);
    });

    test('Details toJson/fromJson roundtrip', () {
      final details = Details.fromJson(makeDetailsJson());
      final reJson = details.toJson();
      final details2 = Details.fromJson(reJson);

      expect(details2.style.idolStyle, details.style.idolStyle);
      expect(details2.activities.recommended, details.activities.recommended);
    });
  });
}
