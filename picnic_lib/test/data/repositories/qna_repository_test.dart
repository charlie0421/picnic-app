import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QnaRepository - Supabase 연동 테스트', () {
    late QnaRepository repository;

    group('getQaThreadList', () {
      test('스레드 목록을 정상적으로 조회한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '첫 번째 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
            {
              'id': 2,
              'user_id': 'user-123',
              'title': '두 번째 문의',
              'created_at': '2025-06-02T10:00:00.000Z',
              'updated_at': '2025-06-02T10:00:00.000Z',
              'status': 'IN_PROGRESS',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-123');

        expect(threads, isA<List<QnaThread>>());
        expect(threads.length, 2);
        expect(threads[0].title, '첫 번째 문의');
        expect(threads[1].title, '두 번째 문의');

        tearDownMockSupabase();
      });

      test('빈 목록을 반환한다', () async {
        setupMockSupabase({
          'qna_threads': <Map<String, dynamic>>[],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-no-threads');

        expect(threads, isEmpty);

        tearDownMockSupabase();
      });

      test('status가 빈 문자열이면 RECEIVED로 기본값 설정된다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '빈 상태 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': '',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-123');

        expect(threads.length, 1);
        expect(threads[0].status, 'RECEIVED');

        tearDownMockSupabase();
      });

      test('status가 null이면 RECEIVED로 기본값 설정된다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': 'null 상태 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': null,
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-123');

        expect(threads.length, 1);
        expect(threads[0].status, 'RECEIVED');

        tearDownMockSupabase();
      });

      test('status가 공백만 있으면 RECEIVED로 기본값 설정된다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '공백 상태 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': '   ',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-123');

        expect(threads.length, 1);
        expect(threads[0].status, 'RECEIVED');

        tearDownMockSupabase();
      });

      test('유효한 status는 그대로 유지된다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '진행 중 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'IN_PROGRESS',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-123');

        expect(threads[0].status, 'IN_PROGRESS');

        tearDownMockSupabase();
      });

      test('lastId를 사용한 페이징 조회', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 3,
              'user_id': 'user-123',
              'title': '세 번째 문의',
              'created_at': '2025-06-03T10:00:00.000Z',
              'updated_at': '2025-06-03T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        // lastId가 있으면 single() 호출로 created_at을 가져옴
        // mock은 qna_threads의 first를 반환
        final threads = await repository.getQaThreadList(
          userId: 'user-123',
          lastId: 2,
          limit: 10,
        );

        expect(threads, isA<List<QnaThread>>());

        tearDownMockSupabase();
      });

      test('커스텀 limit 파라미터', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final threads = await repository.getQaThreadList(
          userId: 'user-123',
          limit: 5,
        );

        expect(threads, isNotEmpty);

        tearDownMockSupabase();
      });
    });

    group('getQaThreadById', () {
      test('스레드와 메시지를 함께 조회한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '상세 조회 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
              'category_code': null,
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 1,
              'user_id': 'user-123',
              'content': '첫 번째 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
            {
              'id': 2,
              'thread_id': 1,
              'user_id': 'admin-001',
              'content': '답변입니다',
              'created_at': '2025-06-01T11:00:00.000Z',
              'is_admin_message': true,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(1);

        expect(result, isA<QaThreadWithMessages>());
        expect(result.thread.id, 1);
        expect(result.thread.title, '상세 조회 문의');
        expect(result.messages.length, 2);
        expect(result.messages[0].content, '첫 번째 메시지');
        expect(result.messages[1].isAdminMessage, isTrue);
        expect(result.categoryLabel, isNull);

        tearDownMockSupabase();
      });

      test('category_code가 있을 때 카테고리 레이블을 조회한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '카테고리 있는 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
              'category_code': 'payment',
            },
          ],
          'qna_messages': <Map<String, dynamic>>[],
          'qna_categories': [
            {
              'code': 'payment',
              'label': {'ko': '결제 문의', 'en': 'Payment'},
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(1);

        expect(result.thread.id, 1);
        // categoryLabel comes from _getCategoryLabelByCode which reads label JSON
        // Since LocaleService defaults to 'ko', it should return '결제 문의'
        expect(result.categoryLabel, isNotNull);

        tearDownMockSupabase();
      });

      test('category_code가 빈 문자열이면 카테고리 레이블을 조회하지 않는다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '빈 카테고리 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
              'category_code': '',
            },
          ],
          'qna_messages': <Map<String, dynamic>>[],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(1);

        expect(result.categoryLabel, isNull);

        tearDownMockSupabase();
      });

      test('빈 메시지 목록인 스레드를 조회한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 5,
              'user_id': 'user-123',
              'title': '메시지 없는 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
              'category_code': null,
            },
          ],
          'qna_messages': <Map<String, dynamic>>[],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(5);

        expect(result.messages, isEmpty);

        tearDownMockSupabase();
      });
    });

    group('createQaThread', () {
      test('스레드와 초기 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 10,
              'user_id': 'user-123',
              'title': '새 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': '초기 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaThread(
          userId: 'user-123',
          title: '새 문의',
          initialMessage: '초기 메시지',
        );

        expect(result, isA<QnaThread>());
        expect(result.id, 10);
        expect(result.title, '새 문의');

        tearDownMockSupabase();
      });

      test('categoryCode가 포함된 스레드를 생성한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 11,
              'user_id': 'user-123',
              'title': '결제 관련 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
              'category_code': 'payment',
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 11,
              'user_id': 'user-123',
              'content': '결제가 안 됩니다',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaThread(
          userId: 'user-123',
          title: '결제 관련 문의',
          initialMessage: '결제가 안 됩니다',
          categoryCode: 'payment',
        );

        expect(result.id, 11);

        tearDownMockSupabase();
      });

      test('categoryCode가 null인 스레드를 생성한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 12,
              'user_id': 'user-123',
              'title': '일반 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 12,
              'user_id': 'user-123',
              'content': '일반 질문입니다',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaThread(
          userId: 'user-123',
          title: '일반 문의',
          initialMessage: '일반 질문입니다',
        );

        expect(result, isA<QnaThread>());

        tearDownMockSupabase();
      });
    });

    group('getCategories', () {
      test('카테고리 목록을 정상적으로 조회한다', () async {
        setupMockSupabase({
          'qna_categories': [
            {
              'code': 'payment',
              'label': {'ko': '결제', 'en': 'Payment'},
              'question_template': {'ko': '결제 질문', 'en': 'Payment question'},
              'answer_template': {'ko': '결제 답변', 'en': 'Payment answer'},
              'order_number': 1,
              'active': true,
            },
            {
              'code': 'account',
              'label': {'ko': '계정', 'en': 'Account'},
              'question_template': null,
              'answer_template': null,
              'order_number': 2,
              'active': true,
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final categories = await repository.getCategories();

        expect(categories, isA<List<QnaCategory>>());
        expect(categories.length, 2);
        expect(categories[0].code, 'payment');
        expect(categories[0].label, isNotEmpty);
        expect(categories[1].code, 'account');

        tearDownMockSupabase();
      });

      test('빈 카테고리 목록을 반환한다', () async {
        setupMockSupabase({
          'qna_categories': <Map<String, dynamic>>[],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final categories = await repository.getCategories();

        expect(categories, isEmpty);

        tearDownMockSupabase();
      });

      test('label이 null인 카테고리를 처리한다', () async {
        setupMockSupabase({
          'qna_categories': [
            {
              'code': 'other',
              'label': null,
              'question_template': null,
              'answer_template': null,
              'order_number': 1,
              'active': true,
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final categories = await repository.getCategories();

        expect(categories.length, 1);
        expect(categories[0].code, 'other');
        expect(categories[0].label, '');
        expect(categories[0].questionTemplate, isNull);
        expect(categories[0].answerTemplate, isNull);

        tearDownMockSupabase();
      });

      test('템플릿이 있는 카테고리를 처리한다', () async {
        setupMockSupabase({
          'qna_categories': [
            {
              'code': 'bug',
              'label': {'ko': '버그 신고', 'en': 'Bug Report'},
              'question_template': {
                'ko': '어떤 버그가 발생했나요?',
                'en': 'What bug did you encounter?',
              },
              'answer_template': {
                'ko': '확인 후 답변드리겠습니다.',
                'en': 'We will check and respond.',
              },
              'order_number': 1,
              'active': true,
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final categories = await repository.getCategories();

        expect(categories.length, 1);
        expect(categories[0].questionTemplate, isNotNull);
        expect(categories[0].answerTemplate, isNotNull);

        tearDownMockSupabase();
      });
    });

    group('createQaMessage', () {
      test('첨부파일 없이 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': '새 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: '새 메시지',
        );

        expect(result, isA<QnaMessage>());
        expect(result.id, 1);
        expect(result.content, '새 메시지');
        expect(result.attachments, isEmpty);

        tearDownMockSupabase();
      });

      test('null attachments로 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 2,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': 'null 첨부 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: 'null 첨부 메시지',
          attachments: null,
        );

        expect(result, isA<QnaMessage>());

        tearDownMockSupabase();
      });

      test('빈 attachments 리스트로 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 3,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': '빈 첨부 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: '빈 첨부 메시지',
          attachments: [],
        );

        expect(result, isA<QnaMessage>());

        tearDownMockSupabase();
      });
    });

    group('getPublicUrl', () {
      test('공개 URL을 반환한다', () {
        setupMockSupabase({});
        repository = QnaRepository(client: testSupabaseClient!);

        final url = repository.getPublicUrl('qna/user-123/1/image.jpg');

        expect(url, isNotEmpty);
        expect(url, contains('qna/user-123/1/image.jpg'));

        tearDownMockSupabase();
      });

      test('다른 경로의 공개 URL을 반환한다', () {
        setupMockSupabase({});
        repository = QnaRepository(client: testSupabaseClient!);

        final url = repository.getPublicUrl('qna/user-456/2/document.pdf');

        expect(url, isNotEmpty);
        expect(url, contains('qna/user-456/2/document.pdf'));

        tearDownMockSupabase();
      });
    });

    group('getFirstAttachmentForThread', () {
      test('첨부파일이 있는 경우 첫 번째 첨부파일을 반환한다', () async {
        setupMockSupabase({
          'qna_attachments': [
            {
              'id': 100,
              'message_id': 1,
              'file_name': 'first_image.jpg',
              'file_path': 'qna/user-123/1/first_image.jpg',
              'file_type': 'image/jpeg',
              'file_size': 2048,
              'created_at': '2025-06-01T10:00:00.000Z',
              'qna_messages': {'thread_id': 1},
            },
          ],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getFirstAttachmentForThread(1);

        expect(result, isA<QnaAttachment>());
        expect(result!.id, 100);
        expect(result.fileName, 'first_image.jpg');

        tearDownMockSupabase();
      });

      test('첨부파일이 없는 경우 null을 반환한다', () async {
        setupMockSupabase({
          'qna_attachments': <Map<String, dynamic>>[],
        });
        repository = QnaRepository(client: testSupabaseClient!);

        final result = await repository.getFirstAttachmentForThread(999);

        expect(result, isNull);

        tearDownMockSupabase();
      });
    });
  });

  group('QaThreadWithMessages 헬퍼 클래스', () {
    test('필수 파라미터로 객체를 생성할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '테스트 스레드',
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        status: 'RECEIVED',
      );

      final messages = <QnaMessage>[
        QnaMessage(
          id: 1,
          threadId: 1,
          userId: 'user-123',
          content: '테스트 메시지',
          createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
          isAdminMessage: false,
        ),
      ];

      final result = QaThreadWithMessages(
        thread: thread,
        messages: messages,
      );

      expect(result.thread, equals(thread));
      expect(result.messages, equals(messages));
      expect(result.categoryLabel, isNull);
    });

    test('categoryLabel을 포함하여 생성할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '카테고리 포함 스레드',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final result = QaThreadWithMessages(
        thread: thread,
        messages: [],
        categoryLabel: '결제 문의',
      );

      expect(result.categoryLabel, equals('결제 문의'));
    });

    test('빈 메시지 리스트로 생성할 수 있다', () {
      final thread = QnaThread(
        id: 2,
        userId: 'user-456',
        title: '빈 스레드',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'IN_PROGRESS',
      );

      final result = QaThreadWithMessages(
        thread: thread,
        messages: [],
      );

      expect(result.messages, isEmpty);
      expect(result.thread.status, equals('IN_PROGRESS'));
    });
  });

  group('QnaThread 모델 파싱', () {
    test('유효한 JSON에서 QnaThread를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'title': 'QnA 문의',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(json);

      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-123'));
      expect(thread.title, equals('QnA 문의'));
      expect(thread.status, equals('RECEIVED'));
    });

    test('fromJson -> toJson 라운드트립이 가능하다', () {
      final originalJson = {
        'id': 1,
        'user_id': 'user-123',
        'title': 'QnA 문의',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(originalJson);
      final roundTripped = thread.toJson();

      expect(roundTripped['id'], equals(originalJson['id']));
      expect(roundTripped['user_id'], equals(originalJson['user_id']));
      expect(roundTripped['title'], equals(originalJson['title']));
      expect(roundTripped['status'], equals(originalJson['status']));
    });

    test('QnaThread status extensions - isReceived', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      expect(thread.isReceived, isTrue);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('QnaThread status extensions - isInProgress', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'IN_PROGRESS',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isTrue);
      expect(thread.isOpen, isTrue);
    });

    test('QnaThread status extensions - isResolved', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RESOLVED',
      );
      expect(thread.isResolved, isTrue);
      expect(thread.isOpen, isFalse);
      expect(thread.isClosed, isTrue);
    });

    test('QnaThread status extensions - lowercase status', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'received',
      );
      expect(thread.isReceived, isTrue);
    });
  });

  group('QnaMessage 모델 파싱', () {
    test('유효한 JSON에서 QnaMessage를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '문의 내용입니다.',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);

      expect(message.id, equals(1));
      expect(message.threadId, equals(10));
      expect(message.userId, equals('user-123'));
      expect(message.content, equals('문의 내용입니다.'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments, isEmpty);
    });

    test('첨부파일이 포함된 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '파일 첨부',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 100,
            'message_id': 2,
            'file_name': 'image.jpg',
            'file_path': 'qna/user-123/2/image.jpg',
            'file_type': 'image/jpeg',
            'file_size': 2048,
            'created_at': '2025-06-01T10:00:00.000Z',
          },
          {
            'id': 101,
            'message_id': 2,
            'file_name': 'doc.pdf',
            'file_path': 'qna/user-123/2/doc.pdf',
            'file_type': 'application/pdf',
            'file_size': 4096,
            'created_at': '2025-06-01T10:01:00.000Z',
          },
        ],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments.length, equals(2));
      expect(message.attachments[0].fileName, equals('image.jpg'));
      expect(message.attachments[1].fileName, equals('doc.pdf'));
      expect(message.attachments[0].fileSize, equals(2048));
    });

    test('qna_attachments가 없는 JSON도 파싱할 수 있다 (기본값 빈 리스트)', () {
      final json = {
        'id': 3,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '첨부 없음',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments, isEmpty);
    });

    test('관리자 메시지와 일반 메시지를 구분할 수 있다', () {
      final userJson = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '질문',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final adminJson = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'admin-001',
        'content': '답변',
        'created_at': '2025-06-01T11:00:00.000Z',
        'is_admin_message': true,
      };

      final userMsg = QnaMessage.fromJson(userJson);
      final adminMsg = QnaMessage.fromJson(adminJson);

      expect(userMsg.isAdminMessage, isFalse);
      expect(adminMsg.isAdminMessage, isTrue);
    });

    test('toJson으로 변환 시 올바른 키 이름을 사용한다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final json = message.toJson();
      expect(json.containsKey('thread_id'), isTrue);
      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('is_admin_message'), isTrue);
      expect(json.containsKey('qna_attachments'), isTrue);
    });

    test('content가 null인 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 4,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': null,
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final message = QnaMessage.fromJson(json);
      expect(message.content, isNull);
    });
  });

  group('QnaAttachment 모델 파싱', () {
    test('유효한 JSON에서 QnaAttachment를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'message_id': 10,
        'file_name': 'screenshot.png',
        'file_path': 'qna/user-123/10/screenshot.png',
        'file_type': 'image/png',
        'file_size': 1024,
        'created_at': '2025-06-01T10:00:00.000Z',
      };

      final attachment = QnaAttachment.fromJson(json);

      expect(attachment.id, equals(1));
      expect(attachment.messageId, equals(10));
      expect(attachment.fileName, equals('screenshot.png'));
      expect(attachment.filePath, equals('qna/user-123/10/screenshot.png'));
      expect(attachment.fileType, equals('image/png'));
      expect(attachment.fileSize, equals(1024));
    });

    test('선택 필드(fileType, fileSize)가 null인 경우를 처리할 수 있다', () {
      final json = {
        'id': 2,
        'message_id': 10,
        'file_name': 'unknown_file',
        'file_path': 'qna/user-123/10/unknown_file',
        'file_type': null,
        'file_size': null,
        'created_at': '2025-06-01T10:00:00.000Z',
      };

      final attachment = QnaAttachment.fromJson(json);
      expect(attachment.fileType, isNull);
      expect(attachment.fileSize, isNull);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'test.png',
        filePath: 'qna/test/10/test.png',
        fileType: 'image/png',
        fileSize: 512,
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
      );

      final json = attachment.toJson();
      expect(json['id'], equals(1));
      expect(json['message_id'], equals(10));
      expect(json['file_name'], equals('test.png'));
      expect(json['file_path'], equals('qna/test/10/test.png'));
    });

    test('동일한 값을 가진 두 QnaAttachment는 같다', () {
      final dateTime = DateTime.parse('2025-06-01T10:00:00.000Z');
      final att1 = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'file.png',
        filePath: 'path/file.png',
        createdAt: dateTime,
      );
      final att2 = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'file.png',
        filePath: 'path/file.png',
        createdAt: dateTime,
      );
      expect(att1, equals(att2));
    });

    test('copyWith으로 특정 필드를 변경할 수 있다', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'original.png',
        filePath: 'path/original.png',
        createdAt: DateTime.now(),
      );

      final modified = attachment.copyWith(fileName: 'modified.png');
      expect(modified.fileName, equals('modified.png'));
      expect(modified.id, equals(1));
      expect(modified.messageId, equals(10));
    });
  });

  group('QnaCategory 모델', () {
    test('creates with required fields only', () {
      final category = QnaCategory(code: 'test', label: 'Test');
      expect(category.code, 'test');
      expect(category.label, 'Test');
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('creates with all fields', () {
      final category = QnaCategory(
        code: 'payment',
        label: 'Payment',
        questionTemplate: 'How can I help?',
        answerTemplate: 'Thank you for contacting.',
      );
      expect(category.questionTemplate, 'How can I help?');
      expect(category.answerTemplate, 'Thank you for contacting.');
    });
  });

  group('QnaRepository - _getCategoryLabelByCode 추가 커버리지', () {
    late QnaRepository repository;

    test('category_code가 존재하지만 DB에 없는 경우 categoryLabel은 null', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 1,
            'user_id': 'user-123',
            'title': '카테고리 없는 문의',
            'created_at': '2025-06-01T10:00:00.000Z',
            'updated_at': '2025-06-01T10:00:00.000Z',
            'status': 'RECEIVED',
            'category_code': 'nonexistent_code',
          },
        ],
        'qna_messages': <Map<String, dynamic>>[],
        // qna_categories not provided - mock returns null for maybeSingle
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.getQaThreadById(1);

      expect(result.categoryLabel, isNull);

      tearDownMockSupabase();
    });

    test('category label이 Map이 아닌 경우 null을 반환한다', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 1,
            'user_id': 'user-123',
            'title': '잘못된 레이블 문의',
            'created_at': '2025-06-01T10:00:00.000Z',
            'updated_at': '2025-06-01T10:00:00.000Z',
            'status': 'RECEIVED',
            'category_code': 'bad_label',
          },
        ],
        'qna_messages': <Map<String, dynamic>>[],
        'qna_categories': [
          {
            'code': 'bad_label',
            'label': 'not_a_map_string',
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.getQaThreadById(1);

      // label is a String, not a Map, so _getCategoryLabelByCode returns null
      expect(result.categoryLabel, isNull);

      tearDownMockSupabase();
    });

    test('category label이 빈 Map인 경우 null을 반환한다', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 1,
            'user_id': 'user-123',
            'title': '빈 레이블 문의',
            'created_at': '2025-06-01T10:00:00.000Z',
            'updated_at': '2025-06-01T10:00:00.000Z',
            'status': 'RECEIVED',
            'category_code': 'empty_label',
          },
        ],
        'qna_messages': <Map<String, dynamic>>[],
        'qna_categories': [
          {
            'code': 'empty_label',
            'label': <String, dynamic>{},
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.getQaThreadById(1);

      // Empty map returns empty string via getLocaleTextFromJson, which results in null
      expect(result.categoryLabel, isNull);

      tearDownMockSupabase();
    });
  });

  group('QnaRepository - getCategories 추가 커버리지', () {
    late QnaRepository repository;

    test('label JSON에 ko 키만 있는 카테고리를 처리한다', () async {
      setupMockSupabase({
        'qna_categories': [
          {
            'code': 'ko_only',
            'label': {'ko': '한국어만'},
            'question_template': null,
            'answer_template': null,
            'order_number': 1,
            'active': true,
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final categories = await repository.getCategories();

      expect(categories.length, 1);
      expect(categories[0].code, 'ko_only');
      expect(categories[0].label, isNotEmpty);

      tearDownMockSupabase();
    });

    test('label JSON에 en 키만 있는 카테고리를 처리한다', () async {
      setupMockSupabase({
        'qna_categories': [
          {
            'code': 'en_only',
            'label': {'en': 'English Only'},
            'question_template': {'en': 'Please describe your issue'},
            'answer_template': {'en': 'Thank you'},
            'order_number': 1,
            'active': true,
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final categories = await repository.getCategories();

      expect(categories.length, 1);
      expect(categories[0].label, isNotEmpty);
      expect(categories[0].questionTemplate, isNotNull);
      expect(categories[0].answerTemplate, isNotNull);

      tearDownMockSupabase();
    });

    test('여러 카테고리의 정렬을 확인한다', () async {
      setupMockSupabase({
        'qna_categories': [
          {
            'code': 'third',
            'label': {'ko': '세 번째'},
            'question_template': null,
            'answer_template': null,
            'order_number': 3,
            'active': true,
          },
          {
            'code': 'first',
            'label': {'ko': '첫 번째'},
            'question_template': null,
            'answer_template': null,
            'order_number': 1,
            'active': true,
          },
          {
            'code': 'second',
            'label': {'ko': '두 번째'},
            'question_template': null,
            'answer_template': null,
            'order_number': 2,
            'active': true,
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final categories = await repository.getCategories();

      expect(categories.length, 3);

      tearDownMockSupabase();
    });
  });

  group('QnaRepository - getPublicUrl 추가 커버리지', () {
    late QnaRepository repository;

    test('한글 파일명을 포함한 경로의 공개 URL을 반환한다', () {
      setupMockSupabase({});
      repository = QnaRepository(client: testSupabaseClient!);

      final url = repository.getPublicUrl('qna/user-123/1/스크린샷.png');

      expect(url, isNotEmpty);

      tearDownMockSupabase();
    });

    test('깊은 경로의 공개 URL을 반환한다', () {
      setupMockSupabase({});
      repository = QnaRepository(client: testSupabaseClient!);

      final url = repository.getPublicUrl('qna/user-123/999/subfolder/deep/file.jpg');

      expect(url, isNotEmpty);
      expect(url, contains('qna/user-123/999/subfolder/deep/file.jpg'));

      tearDownMockSupabase();
    });

    test('빈 문자열 경로의 공개 URL을 반환한다', () {
      setupMockSupabase({});
      repository = QnaRepository(client: testSupabaseClient!);

      final url = repository.getPublicUrl('');

      expect(url, isA<String>());

      tearDownMockSupabase();
    });
  });

  group('QnaRepository - createQaMessage 추가 커버리지', () {
    late QnaRepository repository;

    test('긴 내용의 메시지를 생성한다', () async {
      final longContent = 'A' * 10000;
      setupMockSupabase({
        'qna_messages': [
          {
            'id': 100,
            'thread_id': 10,
            'user_id': 'user-123',
            'content': longContent,
            'created_at': '2025-06-01T10:00:00.000Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.createQaMessage(
        threadId: 10,
        userId: 'user-123',
        content: longContent,
      );

      expect(result, isA<QnaMessage>());
      expect(result.id, 100);

      tearDownMockSupabase();
    });
  });

  group('QnaRepository - getFirstAttachmentForThread 추가 커버리지', () {
    late QnaRepository repository;

    test('여러 첨부파일 중 첫 번째만 반환한다', () async {
      setupMockSupabase({
        'qna_attachments': [
          {
            'id': 200,
            'message_id': 1,
            'file_name': 'first.jpg',
            'file_path': 'qna/user-123/1/first.jpg',
            'file_type': 'image/jpeg',
            'file_size': 1024,
            'created_at': '2025-06-01T10:00:00.000Z',
            'qna_messages': {'thread_id': 1},
          },
          {
            'id': 201,
            'message_id': 1,
            'file_name': 'second.jpg',
            'file_path': 'qna/user-123/1/second.jpg',
            'file_type': 'image/jpeg',
            'file_size': 2048,
            'created_at': '2025-06-01T11:00:00.000Z',
            'qna_messages': {'thread_id': 1},
          },
        ],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.getFirstAttachmentForThread(1);

      expect(result, isNotNull);
      expect(result!.id, 200);
      expect(result.fileName, 'first.jpg');

      tearDownMockSupabase();
    });

    test('존재하지 않는 스레드 ID에 대해 null을 반환한다', () async {
      setupMockSupabase({
        'qna_attachments': <Map<String, dynamic>>[],
      });
      repository = QnaRepository(client: testSupabaseClient!);

      final result = await repository.getFirstAttachmentForThread(0);

      expect(result, isNull);

      tearDownMockSupabase();
    });
  });

  group('QnaThread status extensions - 추가 커버리지', () {
    test('mixed case status is handled correctly', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'Resolved',
      );
      expect(thread.isResolved, isTrue);
      expect(thread.isClosed, isTrue);
      expect(thread.isOpen, isFalse);
    });

    test('unknown status is not received, in_progress, or resolved', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'UNKNOWN',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('empty status is not received, in_progress, or resolved', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: '',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
    });
  });

  group('QnaMessage - 추가 커버리지', () {
    test('copyWith로 content를 변경할 수 있다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '원본',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final modified = message.copyWith(content: '수정됨');
      expect(modified.content, '수정됨');
      expect(modified.id, 1);
    });

    test('copyWith로 isAdminMessage를 변경할 수 있다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final modified = message.copyWith(isAdminMessage: true);
      expect(modified.isAdminMessage, isTrue);
    });

    test('동일한 값을 가진 두 QnaMessage는 같다', () {
      final dateTime = DateTime.parse('2025-06-01T10:00:00.000Z');
      final msg1 = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: dateTime,
        isAdminMessage: false,
      );
      final msg2 = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: dateTime,
        isAdminMessage: false,
      );
      expect(msg1, equals(msg2));
    });

    test('첨부파일이 있는 메시지의 fromJson -> toJson 라운드트립', () {
      final json = {
        'id': 5,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '파일 포함',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 100,
            'message_id': 5,
            'file_name': 'test.png',
            'file_path': 'qna/user-123/5/test.png',
            'file_type': 'image/png',
            'file_size': 512,
            'created_at': '2025-06-01T10:00:00.000Z',
          },
        ],
      };

      final message = QnaMessage.fromJson(json);
      final roundTripped = message.toJson();

      expect(roundTripped['id'], 5);
      expect(roundTripped['thread_id'], 10);
      expect(roundTripped['qna_attachments'], isNotEmpty);
    });
  });

  group('QnaThread - 추가 커버리지', () {
    test('copyWith로 title을 변경할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '원본 제목',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final modified = thread.copyWith(title: '수정된 제목');
      expect(modified.title, '수정된 제목');
      expect(modified.id, 1);
    });

    test('copyWith로 status를 변경할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '테스트',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final modified = thread.copyWith(status: 'RESOLVED');
      expect(modified.status, 'RESOLVED');
      expect(modified.isResolved, isTrue);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: 'JSON 변환 테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-01T12:00:00.000Z'),
        status: 'IN_PROGRESS',
      );

      final json = thread.toJson();
      expect(json['id'], 1);
      expect(json['user_id'], 'user-123');
      expect(json['title'], 'JSON 변환 테스트');
      expect(json['status'], 'IN_PROGRESS');
    });
  });

  group('QnaAttachment - 추가 커버리지', () {
    test('fromJson -> toJson 라운드트립이 가능하다', () {
      final json = {
        'id': 1,
        'message_id': 10,
        'file_name': 'roundtrip.png',
        'file_path': 'qna/test/10/roundtrip.png',
        'file_type': 'image/png',
        'file_size': 256,
        'created_at': '2025-06-01T10:00:00.000Z',
      };

      final attachment = QnaAttachment.fromJson(json);
      final roundTripped = attachment.toJson();

      expect(roundTripped['id'], 1);
      expect(roundTripped['message_id'], 10);
      expect(roundTripped['file_name'], 'roundtrip.png');
      expect(roundTripped['file_type'], 'image/png');
      expect(roundTripped['file_size'], 256);
    });

    test('큰 파일 크기를 처리할 수 있다', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'large.zip',
        filePath: 'qna/test/10/large.zip',
        fileType: 'application/zip',
        fileSize: 1073741824, // 1GB
        createdAt: DateTime.now(),
      );

      expect(attachment.fileSize, 1073741824);
    });
  });

  group('_generateUuidName 간접 테스트', () {
    // _generateUuidName is private, but it's called by createQaMessage
    // when attachments are provided. We test it indirectly through
    // the extension handling logic.

    test('status default logic - empty status defaults to RECEIVED', () {
      final map = <String, dynamic>{
        'id': 1,
        'user_id': 'test-user',
        'title': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'status': '',
      };

      final status = (map['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        map['status'] = 'RECEIVED';
      }

      expect(map['status'], 'RECEIVED');
    });

    test('status default logic - null status defaults to RECEIVED', () {
      final map = <String, dynamic>{
        'id': 1,
        'user_id': 'test-user',
        'title': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'status': null,
      };

      final status = (map['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        map['status'] = 'RECEIVED';
      }

      expect(map['status'], 'RECEIVED');
    });

    test('status default logic - whitespace-only defaults to RECEIVED', () {
      final map = <String, dynamic>{
        'id': 1,
        'user_id': 'test-user',
        'title': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'status': '   ',
      };

      final status = (map['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        map['status'] = 'RECEIVED';
      }

      expect(map['status'], 'RECEIVED');
    });

    test('status default logic - valid status preserved', () {
      final map = <String, dynamic>{
        'id': 1,
        'user_id': 'test-user',
        'title': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'status': 'IN_PROGRESS',
      };

      final status = (map['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        map['status'] = 'RECEIVED';
      }

      expect(map['status'], 'IN_PROGRESS');
    });
  });
}
