import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/fortune.dart';

void main() {
  group('MonthlyFortuneModel serialization', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'month': 3,
        'honor': '좋은 달입니다',
        'career': '승진 기회가 옵니다',
        'health': '건강에 유의하세요',
        'summary': '전반적으로 좋은 달',
      };

      final model = MonthlyFortuneModel.fromJson(json);
      expect(model.month, 3);
      expect(model.honor, '좋은 달입니다');
      expect(model.career, '승진 기회가 옵니다');
      expect(model.health, '건강에 유의하세요');
      expect(model.summary, '전반적으로 좋은 달');

      final output = model.toJson();
      expect(output, json);
    });
  });

  group('AspectModel serialization', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'honor': '명예운 상승',
        'career': '직장운 보통',
        'health': '건강운 주의',
        'finances': '재물운 좋음',
        'relationships': '인간관계 원만',
      };

      final model = AspectModel.fromJson(json);
      expect(model.honor, '명예운 상승');
      expect(model.career, '직장운 보통');
      expect(model.health, '건강운 주의');
      expect(model.finances, '재물운 좋음');
      expect(model.relationships, '인간관계 원만');

      final output = model.toJson();
      expect(output, json);
    });
  });

  group('LuckyModel serialization', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'days': ['월요일', '수요일'],
        'colors': ['빨강', '파랑'],
        'numbers': [3, 7, 12],
        'directions': ['동', '남'],
      };

      final model = LuckyModel.fromJson(json);
      expect(model.days, ['월요일', '수요일']);
      expect(model.colors, ['빨강', '파랑']);
      expect(model.numbers, [3, 7, 12]);
      expect(model.directions, ['동', '남']);

      final output = model.toJson();
      expect(output, json);
    });
  });

  group('FortuneModel serialization', () {
    late Map<String, dynamic> fullJson;

    setUp(() {
      fullJson = {
        'id': 'fortune-001',
        'year': 2026,
        'artist_id': 42,
        'artist': {
          'id': 42,
          'name': {'ko': '지민', 'en': 'Jimin'},
        },
        'overall_luck': '대길',
        'monthly_fortunes': [
          {
            'month': 1,
            'honor': '1월 명예운',
            'career': '1월 직장운',
            'health': '1월 건강운',
            'summary': '1월 요약',
          },
        ],
        'aspects': {
          'honor': '명예 좋음',
          'career': '직장 보통',
          'health': '건강 주의',
          'finances': '재물 상승',
          'relationships': '관계 원만',
        },
        'lucky': {
          'days': ['화요일'],
          'colors': ['노랑'],
          'numbers': [8],
          'directions': ['북'],
        },
        'advice': ['긍정적으로 생각하세요', '건강을 챙기세요'],
      };
    });

    test('fromJson with all nested models', () {
      final model = FortuneModel.fromJson(fullJson);

      expect(model.id, 'fortune-001');
      expect(model.year, 2026);
      expect(model.artistId, 42);
      expect(model.artist.id, 42);
      expect(model.artist.name, {'ko': '지민', 'en': 'Jimin'});
      expect(model.overallLuck, '대길');
      expect(model.monthlyFortunes, hasLength(1));
      expect(model.monthlyFortunes.first.month, 1);
      expect(model.aspects.honor, '명예 좋음');
      expect(model.lucky.days, ['화요일']);
      expect(model.advice, ['긍정적으로 생각하세요', '건강을 챙기세요']);
    });

    test('toJson preserves fields', () {
      final model = FortuneModel.fromJson(fullJson);
      final output = model.toJson();

      expect(output['id'], 'fortune-001');
      expect(output['year'], 2026);
      expect(output['artist_id'], 42);
      expect(output['artist']['id'], 42);
      expect(output['artist']['name'], {'ko': '지민', 'en': 'Jimin'});
      expect(output['overall_luck'], '대길');
      expect(output['monthly_fortunes'], isList);
      expect((output['monthly_fortunes'] as List).first['month'], 1);
      expect(output['aspects']['finances'], '재물 상승');
      expect(output['lucky']['numbers'], [8]);
      expect(output['advice'], hasLength(2));
    });

    test('fromJson with multiple monthly fortunes', () {
      fullJson['monthly_fortunes'] = [
        {
          'month': 1,
          'honor': '1월 명예운',
          'career': '1월 직장운',
          'health': '1월 건강운',
          'summary': '1월 요약',
        },
        {
          'month': 2,
          'honor': '2월 명예운',
          'career': '2월 직장운',
          'health': '2월 건강운',
          'summary': '2월 요약',
        },
        {
          'month': 3,
          'honor': '3월 명예운',
          'career': '3월 직장운',
          'health': '3월 건강운',
          'summary': '3월 요약',
        },
      ];

      final model = FortuneModel.fromJson(fullJson);
      expect(model.monthlyFortunes, hasLength(3));
      expect(model.monthlyFortunes[0].month, 1);
      expect(model.monthlyFortunes[1].month, 2);
      expect(model.monthlyFortunes[2].month, 3);
      expect(model.monthlyFortunes[1].honor, '2월 명예운');
      expect(model.monthlyFortunes[2].summary, '3월 요약');
    });
  });
}
