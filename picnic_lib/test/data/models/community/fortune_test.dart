import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/fortune.dart';

void main() {
  group('MonthlyFortuneModel', () {
    test('생성 확인', () {
      const monthly = MonthlyFortuneModel(
        month: 3,
        honor: '대인운 상승',
        career: '승진 기회',
        health: '건강 주의',
        summary: '좋은 달입니다',
      );
      expect(monthly.month, equals(3));
      expect(monthly.honor, equals('대인운 상승'));
      expect(monthly.career, equals('승진 기회'));
      expect(monthly.health, equals('건강 주의'));
      expect(monthly.summary, equals('좋은 달입니다'));
    });
  });

  group('AspectModel', () {
    test('생성 확인', () {
      const aspect = AspectModel(
        honor: '명예운 좋음',
        career: '직업운 보통',
        health: '건강운 주의',
        finances: '재물운 상승',
        relationships: '연애운 좋음',
      );
      expect(aspect.honor, equals('명예운 좋음'));
      expect(aspect.career, equals('직업운 보통'));
      expect(aspect.health, equals('건강운 주의'));
      expect(aspect.finances, equals('재물운 상승'));
      expect(aspect.relationships, equals('연애운 좋음'));
    });
  });

  group('LuckyModel', () {
    test('생성 확인', () {
      const lucky = LuckyModel(
        days: ['월요일', '수요일'],
        colors: ['파란색', '보라색'],
        numbers: [3, 7, 12],
        directions: ['동쪽', '남쪽'],
      );
      expect(lucky.days.length, equals(2));
      expect(lucky.colors.first, equals('파란색'));
      expect(lucky.numbers, contains(7));
      expect(lucky.directions.last, equals('남쪽'));
    });

    test('빈 리스트', () {
      const lucky = LuckyModel(
        days: [],
        colors: [],
        numbers: [],
        directions: [],
      );
      expect(lucky.days, isEmpty);
      expect(lucky.numbers, isEmpty);
    });
  });
}
