import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';

void main() {
  group('GoonghapStatus', () {
    test('values 확인', () {
      expect(GoonghapStatus.values.length, equals(4));
      expect(GoonghapStatus.values, contains(GoonghapStatus.pending));
      expect(GoonghapStatus.values, contains(GoonghapStatus.completed));
      expect(GoonghapStatus.values, contains(GoonghapStatus.error));
      expect(GoonghapStatus.values, contains(GoonghapStatus.input));
    });
  });

  group('GoonghapStatusX', () {
    test('toJson', () {
      expect(GoonghapStatus.pending.toJson(), equals('pending'));
      expect(GoonghapStatus.completed.toJson(), equals('completed'));
      expect(GoonghapStatus.error.toJson(), equals('error'));
    });

    test('fromJson', () {
      expect(GoonghapStatusX.fromJson('pending'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('completed'), equals(GoonghapStatus.completed));
      expect(GoonghapStatusX.fromJson('error'), equals(GoonghapStatus.error));
    });

    test('fromJson 대소문자 무시', () {
      expect(GoonghapStatusX.fromJson('PENDING'), equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('Completed'), equals(GoonghapStatus.completed));
    });

    test('fromJson 알 수 없는 값이면 ArgumentError', () {
      expect(
        () => GoonghapStatusX.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('LocalizedGoonghap fromJson', () {
    test('기본 생성', () {
      final json = {
        'language': 'ko',
        'score': 85,
        'score_title': '좋은 궁합',
        'goonghap_summary': '궁합 요약',
        'details': {
          'style': {
            'idol_style': '아이돌 스타일',
            'user_style': '사용자 스타일',
            'couple_style': '커플 스타일',
          },
          'activities': {
            'recommended': ['데이트', '쇼핑'],
            'description': '추천 활동 설명',
          },
        },
        'tips': ['팁1', '팁2'],
      };
      final localized = LocalizedGoonghap.fromJson(json);
      expect(localized.language, equals('ko'));
      expect(localized.score, equals(85));
      expect(localized.scoreTitle, equals('좋은 궁합'));
      expect(localized.tips.length, equals(2));
      expect(localized.details, isNotNull);
      expect(localized.details!.style.idolStyle, equals('아이돌 스타일'));
      expect(localized.details!.activities.recommended.length, equals(2));
    });

    test('기본값 확인', () {
      final json = {'language': 'en'};
      final localized = LocalizedGoonghap.fromJson(json);
      expect(localized.score, equals(0));
      expect(localized.scoreTitle, equals(''));
      expect(localized.goonghapSummary, equals(''));
      expect(localized.tips, isEmpty);
    });
  });

  group('Details fromJson', () {
    test('기본 생성', () {
      final json = {
        'style': {
          'idol_style': 'IS',
          'user_style': 'US',
          'couple_style': 'CS',
        },
        'activities': {
          'recommended': ['A', 'B'],
          'description': 'D',
        },
      };
      final details = Details.fromJson(json);
      expect(details.style.idolStyle, equals('IS'));
      expect(details.style.userStyle, equals('US'));
      expect(details.style.coupleStyle, equals('CS'));
      expect(details.activities.recommended, equals(['A', 'B']));
      expect(details.activities.description, equals('D'));
    });
  });
}
