import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';

void main() {
  group('QnaCategory', () {
    test('creates with required fields', () {
      final category = QnaCategory(
        code: 'general',
        label: '일반 문의',
      );
      expect(category.code, 'general');
      expect(category.label, '일반 문의');
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('creates with optional templates', () {
      final category = QnaCategory(
        code: 'payment',
        label: '결제 문의',
        questionTemplate: '결제 관련 문의입니다.',
        answerTemplate: '결제 문의에 대한 답변입니다.',
      );
      expect(category.questionTemplate, '결제 관련 문의입니다.');
      expect(category.answerTemplate, '결제 문의에 대한 답변입니다.');
    });

    test('different categories have different codes', () {
      final a = QnaCategory(code: 'general', label: '일반');
      final b = QnaCategory(code: 'payment', label: '결제');
      expect(a.code, isNot(equals(b.code)));
    });
  });
}
