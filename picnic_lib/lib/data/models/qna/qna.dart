class QnA {
  final int qnaId;
  final String title;
  final String question;
  final String? answer;
  final String status;
  final String? createdBy;
  final String? answeredBy;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  QnA({
    required this.qnaId,
    required this.title,
    required this.question,
    this.answer,
    required this.status,
    this.createdBy,
    this.answeredBy,
    this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory QnA.fromJson(Map<String, dynamic> json) {
    return QnA(
      qnaId: json['qna_id'] as int,
      title: json['title'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      status: json['status'] as String,
      createdBy: json['created_by'] as String?,
      answeredBy: json['answered_by'] as String?,
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qna_id': qnaId,
      'title': title,
      'question': question,
      'answer': answer,
      'status': status,
      'created_by': createdBy,
      'answered_by': answeredBy,
      'answered_at': answeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

class QnAListResponse {
  final List<QnA> items;
  final int totalCount;
  final int page;
  final int pageSize;

  QnAListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory QnAListResponse.fromJson(Map<String, dynamic> json) {
    return QnAListResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => QnA.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

class QnACreateRequest {
  final String title;
  final String question;
  final String createdBy;

  QnACreateRequest({
    required this.title,
    required this.question,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'question': question,
      'created_by': createdBy,
      'status': 'PENDING',
    };
  }
}
