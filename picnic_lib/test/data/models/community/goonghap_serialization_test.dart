import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';

void main() {
  group('GoonghapModel fromJson/toJson', () {
    test('기본 필드 roundtrip', () {
      final json = {
        'id': 'g-123',
        'user_id': 'user-abc',
        'artist': {
          'id': 1,
          'name': {'ko': '정국', 'en': 'Jungkook'},
        },
        'user_birth_date': '2000-01-15T00:00:00.000Z',
        'user_birth_time': '14:30',
        'status': 'completed',
        'gender': 'male',
        'score': 85,
        'goonghap_summary': '환상의 궁합',
        'is_ads': false,
        'is_paid': true,
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.id, equals('g-123'));
      expect(model.userId, equals('user-abc'));
      expect(model.artist.id, equals(1));
      expect(model.birthDate, isA<DateTime>());
      expect(model.birthTime, equals('14:30'));
      expect(model.status, equals(GoonghapStatus.completed));
      expect(model.gender, equals('male'));
      expect(model.score, equals(85));
      expect(model.goonghapSummary, equals('환상의 궁합'));
      expect(model.isAds, isFalse);
      expect(model.isPaid, isTrue);

      final output = model.toJson();
      expect(output['id'], equals('g-123'));
      expect(output['user_id'], equals('user-abc'));
      expect(output['score'], equals(85));
    });

    test('최소 필드로 fromJson', () {
      final json = {
        'id': '',
        'user_id': 'u1',
        'artist': {
          'id': 0,
          'name': {'ko': '테스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.id, equals(''));
      expect(model.birthTime, isNull);
      expect(model.score, isNull);
      expect(model.gender, isNull);
      expect(model.isAds, isNull);
      expect(model.isPaid, isNull);
      expect(model.localizedResults, isNull);
    });

    test('pending 상태 fromJson', () {
      final json = {
        'id': 'g-1',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'status': 'pending',
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.status, equals(GoonghapStatus.pending));
      expect(model.isPending, isTrue);
    });

    test('error 상태 fromJson', () {
      final json = {
        'id': 'g-2',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'status': 'error',
        'error_message': '서버 오류',
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.status, equals(GoonghapStatus.error));
      expect(model.hasError, isTrue);
    });

    test('details 포함 fromJson', () {
      final json = {
        'id': 'g-3',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'status': 'completed',
        'details': {
          'style': {
            'idol_style': '카리스마',
            'user_style': '다정한',
            'couple_style': '환상',
          },
          'activities': {
            'recommended': ['카페', '영화', '여행'],
            'description': '함께하면 좋은 활동들',
          },
        },
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.details, isNotNull);
      expect(model.details!.style.idolStyle, equals('카리스마'));
      expect(model.details!.style.userStyle, equals('다정한'));
      expect(model.details!.style.coupleStyle, equals('환상'));
      expect(model.details!.activities.recommended.length, equals(3));
      expect(model.details!.activities.description, equals('함께하면 좋은 활동들'));
    });

    test('tips 포함 fromJson', () {
      final json = {
        'id': 'g-4',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'tips': ['팁1', '팁2'],
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.tips, equals(['팁1', '팁2']));
    });

    test('i18n Map 형태 fromJson', () {
      final json = {
        'id': 'g-5',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': {
          'ko': {
            'language': 'ko',
            'score': 90,
            'score_title': '최고',
            'goonghap_summary': '궁합 요약 한국어',
            'tips': ['팁A'],
          },
          'en': {
            'language': 'en',
            'score': 88,
            'score_title': 'Best',
            'goonghap_summary': 'English summary',
            'tips': ['tipB'],
          },
        },
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(2));
      expect(model.localizedResults!['ko']!.score, equals(90));
      expect(model.localizedResults!['ko']!.scoreTitle, equals('최고'));
      expect(model.localizedResults!['en']!.goonghapSummary,
          equals('English summary'));
    });

    test('i18n List 형태 fromJson', () {
      final json = {
        'id': 'g-6',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': [
          {
            'language': 'ko',
            'score': 75,
            'score_title': '좋음',
            'goonghap_summary': '한국어 요약',
          },
          {
            'language': 'ja',
            'score': 80,
            'score_title': '良い',
            'goonghap_summary': '日本語の要約',
          },
        ],
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(2));
      expect(model.localizedResults!['ko']!.score, equals(75));
      expect(model.localizedResults!['ja']!.scoreTitle, equals('良い'));
    });

    test('i18n null이면 localizedResults null', () {
      final json = {
        'id': 'g-7',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': null,
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
    });

    test('i18n 빈 맵이면 localizedResults null', () {
      final json = {
        'id': 'g-8',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': {},
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
    });

    test('i18n 빈 리스트면 localizedResults null', () {
      final json = {
        'id': 'g-9',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': [],
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNull);
    });

    test('i18n List에서 language 없는 항목은 무시', () {
      final json = {
        'id': 'g-10',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': [
          {
            'score': 70,
            'score_title': '보통',
            'goonghap_summary': '요약',
          },
          {
            'language': 'ko',
            'score': 80,
            'score_title': '좋음',
            'goonghap_summary': '한국어',
          },
        ],
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(1));
      expect(model.localizedResults!['ko']!.score, equals(80));
    });

    test('i18n List에서 Map이 아닌 항목은 무시', () {
      final json = {
        'id': 'g-11',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': [
          'invalid_string',
          42,
          {
            'language': 'ko',
            'score': 90,
            'score_title': '최고',
            'goonghap_summary': '요약',
          },
        ],
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(1));
    });

    test('i18n Map에서 값이 Map이 아닌 항목은 무시', () {
      final json = {
        'id': 'g-12',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'i18n': {
          'ko': {
            'language': 'ko',
            'score': 85,
            'score_title': '좋음',
            'goonghap_summary': '요약',
          },
          'invalid': 'not_a_map',
          'also_invalid': 42,
        },
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.localizedResults, isNotNull);
      expect(model.localizedResults!.length, equals(1));
      expect(model.localizedResults!['ko']!.score, equals(85));
    });

    test('createdAt, completedAt 포함 fromJson', () {
      final json = {
        'id': 'g-13',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '아티스트'},
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'created_at': '2025-01-01T00:00:00.000Z',
        'completed_at': '2025-01-02T00:00:00.000Z',
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.createdAt, isNotNull);
      expect(model.completedAt, isNotNull);
    });

    test('toJson roundtrip 검증', () {
      final json = {
        'id': 'g-rt',
        'user_id': 'u1',
        'artist': {
          'id': 1,
          'name': {'ko': '정국'},
        },
        'user_birth_date': '2000-06-15T00:00:00.000Z',
        'user_birth_time': '10:00',
        'status': 'completed',
        'gender': 'male',
        'score': 92,
        'goonghap_summary': '완벽한 궁합',
        'tips': ['팁1', '팁2'],
        'is_ads': true,
        'is_paid': false,
      };
      final model = GoonghapModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], equals('g-rt'));
      expect(output['user_id'], equals('u1'));
      expect(output['score'], equals(92));
      expect(output['goonghap_summary'], equals('완벽한 궁합'));
      expect(output['gender'], equals('male'));
      expect(output['tips'], equals(['팁1', '팁2']));
      expect(output['is_ads'], isTrue);
      expect(output['is_paid'], isFalse);
    });
  });

  group('GoonghapHistoryModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'items': [
          {
            'id': 'g-h1',
            'user_id': 'u1',
            'artist': {
              'id': 1,
              'name': {'ko': '아티스트'},
            },
            'user_birth_date': '2000-01-01T00:00:00.000Z',
            'status': 'completed',
            'score': 80,
          },
        ],
        'has_more': true,
        'is_loading': false,
      };
      final history = GoonghapHistoryModel.fromJson(json);
      expect(history.items.length, equals(1));
      expect(history.hasMore, isTrue);
      expect(history.isLoading, isFalse);
      expect(history.items.first.score, equals(80));

      final output = history.toJson();
      expect(output['has_more'], isTrue);
      expect((output['items'] as List).length, equals(1));
    });

    test('빈 히스토리', () {
      final json = {
        'items': [],
        'has_more': false,
      };
      final history = GoonghapHistoryModel.fromJson(json);
      expect(history.items, isEmpty);
      expect(history.hasMore, isFalse);
      expect(history.isLoading, isFalse); // default
    });
  });

  group('LocalizedGoonghap fromJson/toJson', () {
    test('전체 필드 roundtrip', () {
      final json = {
        'language': 'ko',
        'score': 95,
        'score_title': '최고의 궁합',
        'goonghap_summary': '당신은 환상의 짝꿍!',
        'details': {
          'style': {
            'idol_style': '카리스마',
            'user_style': '유머',
            'couple_style': '밸런스',
          },
          'activities': {
            'recommended': ['여행', '요리'],
            'description': '함께하면 좋은 활동',
          },
        },
        'tips': ['팁A', '팁B', '팁C'],
      };
      final lg = LocalizedGoonghap.fromJson(json);
      expect(lg.language, equals('ko'));
      expect(lg.score, equals(95));
      expect(lg.scoreTitle, equals('최고의 궁합'));
      expect(lg.details, isNotNull);
      expect(lg.details!.style.idolStyle, equals('카리스마'));
      expect(lg.tips.length, equals(3));

      final output = lg.toJson();
      expect(output['language'], equals('ko'));
      expect(output['score'], equals(95));
    });

    test('최소 필드', () {
      final json = {
        'language': 'en',
      };
      final lg = LocalizedGoonghap.fromJson(json);
      expect(lg.language, equals('en'));
      expect(lg.score, equals(0)); // default
      expect(lg.scoreTitle, equals('')); // default
      expect(lg.goonghapSummary, equals('')); // default
      expect(lg.details, isNull);
      expect(lg.tips, isEmpty); // default
    });
  });

  group('Details fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'style': {
          'idol_style': 'cool',
          'user_style': 'warm',
          'couple_style': 'harmony',
        },
        'activities': {
          'recommended': ['travel', 'cooking'],
          'description': 'Great together',
        },
      };
      final details = Details.fromJson(json);
      expect(details.style.idolStyle, equals('cool'));
      expect(details.activities.recommended, equals(['travel', 'cooking']));

      final output = details.toJson();
      expect((output['style'] as Map)['idol_style'], equals('cool'));
      expect(
        ((output['activities'] as Map)['recommended'] as List).length,
        equals(2),
      );
    });
  });

  group('StyleDetails fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'idol_style': 'charisma',
        'user_style': 'gentle',
        'couple_style': 'perfect match',
      };
      final style = StyleDetails.fromJson(json);
      expect(style.idolStyle, equals('charisma'));
      expect(style.userStyle, equals('gentle'));
      expect(style.coupleStyle, equals('perfect match'));

      final output = style.toJson();
      expect(output['idol_style'], equals('charisma'));
    });
  });

  group('ActivitiesDetails fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'recommended': ['cafe', 'movie', 'travel'],
        'description': 'Activities you would enjoy together',
      };
      final activities = ActivitiesDetails.fromJson(json);
      expect(activities.recommended.length, equals(3));
      expect(activities.description, contains('enjoy'));

      final output = activities.toJson();
      expect((output['recommended'] as List).length, equals(3));
    });

    test('빈 recommended', () {
      final json = {
        'recommended': [],
        'description': 'No recommendations',
      };
      final activities = ActivitiesDetails.fromJson(json);
      expect(activities.recommended, isEmpty);
    });
  });

  group('GoonghapStatusX', () {
    test('toJson은 name 반환', () {
      expect(GoonghapStatusX(GoonghapStatus.pending).toJson(), equals('pending'));
      expect(
          GoonghapStatusX(GoonghapStatus.completed).toJson(), equals('completed'));
      expect(GoonghapStatusX(GoonghapStatus.error).toJson(), equals('error'));
      expect(GoonghapStatusX(GoonghapStatus.input).toJson(), equals('input'));
    });

    test('fromJson 정상 변환', () {
      expect(
          GoonghapStatusX.fromJson('pending'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('completed'),
          equals(GoonghapStatus.completed));
      expect(GoonghapStatusX.fromJson('error'), equals(GoonghapStatus.error));
    });

    test('fromJson 대소문자 무시', () {
      expect(
          GoonghapStatusX.fromJson('PENDING'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('Completed'),
          equals(GoonghapStatus.completed));
      expect(GoonghapStatusX.fromJson('ERROR'), equals(GoonghapStatus.error));
    });

    test('fromJson 알 수 없는 상태는 ArgumentError', () {
      expect(
          () => GoonghapStatusX.fromJson('unknown'), throwsA(isA<ArgumentError>()));
    });
  });
}
