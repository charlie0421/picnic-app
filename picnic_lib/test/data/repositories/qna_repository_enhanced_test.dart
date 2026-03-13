import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QaThreadWithMessages', () {
    test('creates with required fields', () {
      final thread = QnaThread.fromJson({
        'id': 1,
        'user_id': 'user-1',
        'title': 'Test Thread',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'status': 'RECEIVED',
      });

      final result = QaThreadWithMessages(
        thread: thread,
        messages: [],
      );

      expect(result.thread.id, 1);
      expect(result.thread.title, 'Test Thread');
      expect(result.messages, isEmpty);
      expect(result.categoryLabel, isNull);
    });

    test('creates with category label', () {
      final thread = QnaThread.fromJson({
        'id': 2,
        'user_id': 'user-1',
        'title': 'Support Request',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'status': 'IN_PROGRESS',
      });

      final result = QaThreadWithMessages(
        thread: thread,
        messages: [],
        categoryLabel: 'Account Issues',
      );

      expect(result.categoryLabel, 'Account Issues');
    });

    test('creates with messages', () {
      final thread = QnaThread.fromJson({
        'id': 3,
        'user_id': 'user-1',
        'title': 'Thread with messages',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'status': 'RESOLVED',
      });

      final messages = [
        QnaMessage.fromJson({
          'id': 1,
          'thread_id': 3,
          'user_id': 'user-1',
          'content': 'Hello',
          'created_at': '2025-01-01T00:00:00Z',
          'is_admin_message': false,
          'qna_attachments': [],
        }),
        QnaMessage.fromJson({
          'id': 2,
          'thread_id': 3,
          'user_id': 'admin',
          'content': 'Hi, how can I help?',
          'created_at': '2025-01-01T01:00:00Z',
          'is_admin_message': true,
          'qna_attachments': [],
        }),
      ];

      final result = QaThreadWithMessages(
        thread: thread,
        messages: messages,
        categoryLabel: 'General',
      );

      expect(result.messages.length, 2);
      expect(result.messages[0].content, 'Hello');
      expect(result.messages[1].content, 'Hi, how can I help?');
    });
  });

  group('QnaRepository - getPublicUrl', () {
    late QnaRepository repository;

    setUp(() {
      setupMockSupabase({});
      repository = QnaRepository(client: testSupabaseClient!);
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('returns a URL string for a valid path', () {
      final url = repository.getPublicUrl('qna/user-1/1/image.png');
      expect(url, isNotEmpty);
      expect(url, contains('qna/user-1/1/image.png'));
    });

    test('returns URL with different paths', () {
      final url1 = repository.getPublicUrl('path/a.jpg');
      final url2 = repository.getPublicUrl('path/b.png');
      expect(url1, isNot(url2));
    });
  });

  group('QnaRepository - getQaThreadList with pagination', () {
    late QnaRepository repository;

    setUp(() {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 5,
            'user_id': 'user-123',
            'title': 'Thread 5',
            'created_at': '2025-06-05T10:00:00.000Z',
            'updated_at': '2025-06-05T10:00:00.000Z',
            'status': 'RECEIVED',
          },
          {
            'id': 4,
            'user_id': 'user-123',
            'title': 'Thread 4',
            'created_at': '2025-06-04T10:00:00.000Z',
            'updated_at': '2025-06-04T10:00:00.000Z',
            'status': 'IN_PROGRESS',
          },
          {
            'id': 3,
            'user_id': 'user-123',
            'title': 'Thread 3',
            'created_at': '2025-06-03T10:00:00.000Z',
            'updated_at': '2025-06-03T10:00:00.000Z',
            'status': null,
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('fetches threads without pagination', () async {
      final threads = await repository.getQaThreadList(userId: 'user-123');
      expect(threads, isNotEmpty);
      expect(threads.length, 3);
    });

    test('thread with null status defaults to RECEIVED', () async {
      final threads = await repository.getQaThreadList(userId: 'user-123');
      // Thread 3 has null status, should default to RECEIVED
      final thread3 = threads.firstWhere((t) => t.id == 3);
      expect(thread3.status, 'RECEIVED');
    });

    test('thread with empty status defaults to RECEIVED', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 1,
            'user_id': 'user-1',
            'title': 'Empty status',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': '',
          },
        ],
      });
      final repo = QnaRepository(client: testSupabaseClient!);
      final threads = await repo.getQaThreadList(userId: 'user-1');
      expect(threads.first.status, 'RECEIVED');
    });

    test('thread with whitespace-only status defaults to RECEIVED', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 1,
            'user_id': 'user-1',
            'title': 'Whitespace status',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': '   ',
          },
        ],
      });
      final repo = QnaRepository(client: testSupabaseClient!);
      final threads = await repo.getQaThreadList(userId: 'user-1');
      expect(threads.first.status, 'RECEIVED');
    });
  });

  group('QnaRepository - getCategories', () {
    late QnaRepository repository;

    setUp(() {
      setupMockSupabase({
        'qna_categories': [
          {
            'code': 'ACCOUNT',
            'label': {'ko': '계정', 'en': 'Account'},
            'question_template': {'ko': '계정 관련 질문', 'en': 'Account question'},
            'answer_template': {'ko': '계정 답변', 'en': 'Account answer'},
            'order_number': 1,
            'active': true,
          },
          {
            'code': 'PAYMENT',
            'label': {'ko': '결제', 'en': 'Payment'},
            'question_template': null,
            'answer_template': null,
            'order_number': 2,
            'active': true,
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('fetches categories with labels', () async {
      final categories = await repository.getCategories();
      expect(categories, isA<List<QnaCategory>>());
      expect(categories.length, 2);
      expect(categories[0].code, 'ACCOUNT');
      expect(categories[1].code, 'PAYMENT');
    });

    test('category with null templates', () async {
      final categories = await repository.getCategories();
      final payment = categories.firstWhere((c) => c.code == 'PAYMENT');
      expect(payment.questionTemplate, isNull);
      expect(payment.answerTemplate, isNull);
    });
  });

  group('QnaRepository - getFirstAttachmentForThread', () {
    late QnaRepository repository;

    setUp(() {
      setupMockSupabase({
        'qna_attachments': <Map<String, dynamic>>[],
      });
      repository = QnaRepository(client: testSupabaseClient!);
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('returns null when no attachments exist', () async {
      final result = await repository.getFirstAttachmentForThread(1);
      expect(result, isNull);
    });
  });

  group('QnaRepository constructor', () {
    test('creates with custom client', () {
      setupMockSupabase({});
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      expect(repo, isNotNull);
    });
  });
}
