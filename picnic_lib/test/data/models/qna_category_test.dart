import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';

void main() {
  group('QnaCategory', () {
    test('필수 파라미터로 생성', () {
      final category = QnaCategory(
        code: 'general',
        label: '일반 문의',
      );
      expect(category.code, equals('general'));
      expect(category.label, equals('일반 문의'));
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('전체 파라미터로 생성', () {
      final category = QnaCategory(
        code: 'account',
        label: '계정 문의',
        questionTemplate: '계정 관련 질문입니다: {question}',
        answerTemplate: '답변: {answer}',
      );
      expect(category.code, equals('account'));
      expect(category.label, equals('계정 문의'));
      expect(category.questionTemplate, equals('계정 관련 질문입니다: {question}'));
      expect(category.answerTemplate, equals('답변: {answer}'));
    });

    test('빈 코드와 라벨로 생성 가능', () {
      final category = QnaCategory(code: '', label: '');
      expect(category.code, isEmpty);
      expect(category.label, isEmpty);
    });
  });
}
