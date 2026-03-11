import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap_result.dart';

void main() {
  group('GoonghapResult', () {
    test('필수 파라미터로 생성', () {
      final now = DateTime.now();
      final result = GoonghapResult(
        id: 'result-1',
        userId: 'user-1',
        idolName: 'BTS 정국',
        userBirthDate: DateTime(2000, 1, 1),
        idolBirthDate: DateTime(1997, 9, 1),
        userGender: 'female',
        goonghapScore: 85,
        goonghapSummary: '환상의 궁합',
        details: null,
        tips: null,
        createdAt: now,
      );
      expect(result.id, equals('result-1'));
      expect(result.idolName, equals('BTS 정국'));
      expect(result.goonghapScore, equals(85));
      expect(result.birthTime, isNull);
      expect(result.tips, isNull);
    });

    test('선택 필드 포함 생성', () {
      final result = GoonghapResult(
        id: 'result-2',
        userId: 'user-2',
        idolName: 'V',
        userBirthDate: DateTime(1999, 5, 15),
        idolBirthDate: DateTime(1995, 12, 30),
        userGender: 'male',
        birthTime: '14:30',
        goonghapScore: 92,
        goonghapSummary: '최고의 궁합',
        details: {'style': 'romantic'},
        tips: ['팁1', '팁2', '팁3'],
        createdAt: DateTime.now(),
      );
      expect(result.birthTime, equals('14:30'));
      expect(result.tips!.length, equals(3));
      expect(result.details!['style'], equals('romantic'));
    });
  });

  group('StyleDetails (goonghap_result)', () {
    test('생성 확인', () {
      const details = StyleDetails(
        idolStyle: '카리스마',
        userStyle: '다정한',
        coupleStyle: '로맨틱',
      );
      expect(details.idolStyle, equals('카리스마'));
      expect(details.userStyle, equals('다정한'));
      expect(details.coupleStyle, equals('로맨틱'));
    });

    test('nullable 필드', () {
      const details = StyleDetails(
        idolStyle: null,
        userStyle: null,
        coupleStyle: null,
      );
      expect(details.idolStyle, isNull);
    });
  });

  group('ActivitiesDetails (goonghap_result)', () {
    test('생성 확인', () {
      const details = ActivitiesDetails(
        recommended: ['카페 데이트', '영화 감상'],
        description: '함께하면 좋은 활동들',
      );
      expect(details.recommended!.length, equals(2));
      expect(details.description, equals('함께하면 좋은 활동들'));
    });

    test('nullable 필드', () {
      const details = ActivitiesDetails(
        recommended: null,
        description: null,
      );
      expect(details.recommended, isNull);
      expect(details.description, isNull);
    });
  });
}
