import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';

void main() {
  group('GoonghapStatus enum', () {
    test('4개의 상태값이 정의됨', () {
      expect(GoonghapStatus.values.length, equals(4));
    });

    test('모든 상태값 존재', () {
      expect(GoonghapStatus.pending, isNotNull);
      expect(GoonghapStatus.completed, isNotNull);
      expect(GoonghapStatus.error, isNotNull);
      expect(GoonghapStatus.input, isNotNull);
    });

    test('index 순서', () {
      expect(GoonghapStatus.pending.index, equals(0));
      expect(GoonghapStatus.completed.index, equals(1));
      expect(GoonghapStatus.error.index, equals(2));
      expect(GoonghapStatus.input.index, equals(3));
    });
  });

  group('GoonghapStatusX extension', () {
    test('toJson - pending', () {
      expect(GoonghapStatus.pending.toJson(), equals('pending'));
    });

    test('toJson - completed', () {
      expect(GoonghapStatus.completed.toJson(), equals('completed'));
    });

    test('toJson - error', () {
      expect(GoonghapStatus.error.toJson(), equals('error'));
    });

    test('fromJson - pending', () {
      expect(GoonghapStatusX.fromJson('pending'),
          equals(GoonghapStatus.pending));
    });

    test('fromJson - completed', () {
      expect(GoonghapStatusX.fromJson('completed'),
          equals(GoonghapStatus.completed));
    });

    test('fromJson - error', () {
      expect(
          GoonghapStatusX.fromJson('error'), equals(GoonghapStatus.error));
    });

    test('fromJson - 대소문자 무시', () {
      expect(GoonghapStatusX.fromJson('PENDING'),
          equals(GoonghapStatus.pending));
      expect(GoonghapStatusX.fromJson('Completed'),
          equals(GoonghapStatus.completed));
    });

    test('fromJson - 알 수 없는 값이면 ArgumentError', () {
      expect(
          () => GoonghapStatusX.fromJson('unknown'), throwsArgumentError);
    });
  });

  group('LocalizedGoonghap 기본값', () {
    test('기본값 확인', () {
      const localized = LocalizedGoonghap(language: 'ko');
      expect(localized.language, equals('ko'));
      expect(localized.score, equals(0));
      expect(localized.scoreTitle, isEmpty);
      expect(localized.goonghapSummary, isEmpty);
      expect(localized.details, isNull);
      expect(localized.tips, isEmpty);
    });

    test('전체 파라미터 생성', () {
      const localized = LocalizedGoonghap(
        language: 'ko',
        score: 85,
        scoreTitle: '환상의 궁합',
        goonghapSummary: '아주 좋은 궁합입니다',
        tips: ['팁1', '팁2'],
      );
      expect(localized.score, equals(85));
      expect(localized.scoreTitle, equals('환상의 궁합'));
      expect(localized.tips.length, equals(2));
    });
  });

  group('GoonghapHistoryModel 기본값', () {
    test('isLoading 기본값은 false', () {
      const history = GoonghapHistoryModel(
        items: [],
        hasMore: false,
      );
      expect(history.isLoading, isFalse);
      expect(history.items, isEmpty);
      expect(history.hasMore, isFalse);
    });
  });
}
