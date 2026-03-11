import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap_result.dart';

void main() {
  group('GoonghapResult', () {
    test('필수 필드로 생성', () {
      final result = GoonghapResult(
        id: 'result-1',
        userId: 'user-abc',
        idolName: '지민',
        userBirthDate: DateTime(2000, 1, 15),
        idolBirthDate: DateTime(1995, 10, 13),
        userGender: 'F',
        goonghapScore: 85,
        goonghapSummary: '좋은 궁합입니다',
        details: null,
        tips: null,
        createdAt: DateTime(2025, 3, 1),
      );
      expect(result.id, equals('result-1'));
      expect(result.idolName, equals('지민'));
      expect(result.goonghapScore, equals(85));
      expect(result.goonghapSummary, equals('좋은 궁합입니다'));
      expect(result.birthTime, isNull);
      expect(result.details, isNull);
      expect(result.tips, isNull);
    });

    test('birthTime 포함', () {
      final result = GoonghapResult(
        id: 'result-2',
        userId: 'user-xyz',
        idolName: '뷔',
        userBirthDate: DateTime(1998, 5, 20),
        idolBirthDate: DateTime(1995, 12, 30),
        userGender: 'M',
        birthTime: '14:30',
        goonghapScore: 92,
        goonghapSummary: '최고의 궁합!',
        details: {'style': 'romantic', 'compatibility': 'high'},
        tips: ['데이트 추천: 카페', '선물 추천: 꽃'],
        createdAt: DateTime(2025, 3, 10),
      );
      expect(result.birthTime, equals('14:30'));
      expect(result.details!['style'], equals('romantic'));
      expect(result.tips!.length, equals(2));
    });

    test('낮은 점수', () {
      final result = GoonghapResult(
        id: 'result-3',
        userId: 'user-low',
        idolName: '테스트',
        userBirthDate: DateTime(2002, 8, 1),
        idolBirthDate: DateTime(1990, 3, 15),
        userGender: 'F',
        goonghapScore: 30,
        goonghapSummary: null,
        details: null,
        tips: null,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(result.goonghapScore, equals(30));
      expect(result.goonghapSummary, isNull);
    });
  });

  group('StyleDetails', () {
    test('모든 필드 포함', () {
      const style = StyleDetails(
        idolStyle: '감성적',
        userStyle: '활발한',
        coupleStyle: '밸런스 커플',
      );
      expect(style.idolStyle, equals('감성적'));
      expect(style.userStyle, equals('활발한'));
      expect(style.coupleStyle, equals('밸런스 커플'));
    });

    test('null 필드', () {
      const style = StyleDetails(
        idolStyle: null,
        userStyle: null,
        coupleStyle: null,
      );
      expect(style.idolStyle, isNull);
      expect(style.userStyle, isNull);
      expect(style.coupleStyle, isNull);
    });
  });

  group('ActivitiesDetails', () {
    test('추천 활동 포함', () {
      const activities = ActivitiesDetails(
        recommended: ['영화 감상', '산책', '카페 투어'],
        description: '함께 즐길 수 있는 활동들',
      );
      expect(activities.recommended!.length, equals(3));
      expect(activities.description, equals('함께 즐길 수 있는 활동들'));
    });

    test('null 필드', () {
      const activities = ActivitiesDetails(
        recommended: null,
        description: null,
      );
      expect(activities.recommended, isNull);
      expect(activities.description, isNull);
    });

    test('빈 추천 리스트', () {
      const activities = ActivitiesDetails(
        recommended: [],
        description: '추천 활동 없음',
      );
      expect(activities.recommended, isEmpty);
    });
  });
}
