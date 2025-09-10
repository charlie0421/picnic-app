class QnaCategory {
  final String code;
  final String label;
  final String? questionTemplate;
  final String? answerTemplate;

  QnaCategory({
    required this.code,
    required this.label,
    this.questionTemplate,
    this.answerTemplate,
  });
}
