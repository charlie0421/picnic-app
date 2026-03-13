import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qa_repository.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QaRepository - Supabase 연동 테스트', () {
    late QaRepository repository;

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
            {
              'id': 3,
              'user_id': 'user-123',
              'title': '세 번째 문의',
              'created_at': '2025-06-03T10:00:00.000Z',
              'updated_at': '2025-06-03T10:00:00.000Z',
              'status': 'RESOLVED',
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final threads = await repository.getQaThreadList(userId: 'user-123');

        expect(threads, isA<List<QnaThread>>());
        expect(threads.length, 3);
        expect(threads[0].title, '첫 번째 문의');
        expect(threads[0].status, 'RECEIVED');
        expect(threads[1].title, '두 번째 문의');
        expect(threads[1].status, 'IN_PROGRESS');
        expect(threads[2].title, '세 번째 문의');
        expect(threads[2].status, 'RESOLVED');

        tearDownMockSupabase();
      });

      test('빈 스레드 목록을 반환한다', () async {
        setupMockSupabase({
          'qna_threads': <Map<String, dynamic>>[],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final threads =
            await repository.getQaThreadList(userId: 'user-no-threads');

        expect(threads, isEmpty);

        tearDownMockSupabase();
      });

      test('단일 스레드를 반환한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-abc',
              'title': '유일한 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final threads = await repository.getQaThreadList(userId: 'user-abc');

        expect(threads.length, 1);
        expect(threads[0].userId, 'user-abc');

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
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(1);

        expect(result, isA<QaThreadWithMessages>());
        expect(result.thread.id, 1);
        expect(result.thread.title, '상세 조회 문의');
        expect(result.messages.length, 2);
        expect(result.messages[0].content, '첫 번째 메시지');
        expect(result.messages[0].isAdminMessage, isFalse);
        expect(result.messages[1].content, '답변입니다');
        expect(result.messages[1].isAdminMessage, isTrue);

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
            },
          ],
          'qna_messages': <Map<String, dynamic>>[],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(5);

        expect(result.thread.id, 5);
        expect(result.messages, isEmpty);

        tearDownMockSupabase();
      });

      test('첨부파일이 포함된 메시지가 있는 스레드를 조회한다', () async {
        setupMockSupabase({
          'qna_threads': [
            {
              'id': 1,
              'user_id': 'user-123',
              'title': '첨부파일 포함 문의',
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'IN_PROGRESS',
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 1,
              'user_id': 'user-123',
              'content': '파일 첨부합니다',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [
                {
                  'id': 100,
                  'message_id': 1,
                  'file_name': 'screenshot.png',
                  'file_path': 'qna/user-123/1/screenshot.png',
                  'file_type': 'image/png',
                  'file_size': 1024,
                  'created_at': '2025-06-01T10:00:00.000Z',
                },
              ],
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.getQaThreadById(1);

        expect(result.messages.length, 1);
        expect(result.messages[0].attachments.length, 1);
        expect(result.messages[0].attachments[0].fileName, 'screenshot.png');

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
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaThread(
          userId: 'user-123',
          title: '새 문의',
          initialMessage: '초기 메시지',
        );

        expect(result, isA<QnaThread>());
        expect(result.id, 10);
        expect(result.title, '새 문의');
        expect(result.userId, 'user-123');
        expect(result.status, 'RECEIVED');

        tearDownMockSupabase();
      });

      test('긴 제목과 내용으로 스레드를 생성한다', () async {
        final longTitle = 'A' * 200;
        final longMessage = 'B' * 1000;

        setupMockSupabase({
          'qna_threads': [
            {
              'id': 11,
              'user_id': 'user-456',
              'title': longTitle,
              'created_at': '2025-06-01T10:00:00.000Z',
              'updated_at': '2025-06-01T10:00:00.000Z',
              'status': 'RECEIVED',
            },
          ],
          'qna_messages': [
            {
              'id': 1,
              'thread_id': 11,
              'user_id': 'user-456',
              'content': longMessage,
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaThread(
          userId: 'user-456',
          title: longTitle,
          initialMessage: longMessage,
        );

        expect(result.title, longTitle);

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
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: '새 메시지',
        );

        expect(result, isA<QnaMessage>());
        expect(result.id, 1);
        expect(result.content, '새 메시지');
        expect(result.threadId, 10);
        expect(result.userId, 'user-123');
        expect(result.isAdminMessage, isFalse);
        expect(result.attachments, isEmpty);

        tearDownMockSupabase();
      });

      test('attachments가 null인 경우 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 2,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': 'null attachments',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: 'null attachments',
          attachments: null,
        );

        expect(result, isA<QnaMessage>());
        expect(result.id, 2);

        tearDownMockSupabase();
      });

      test('빈 attachments 리스트로 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 3,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': 'empty attachments',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [],
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: 'empty attachments',
          attachments: [],
        );

        expect(result, isA<QnaMessage>());

        tearDownMockSupabase();
      });

      test('첨부파일 메타데이터와 함께 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 4,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': '파일 첨부 메시지',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [
                {
                  'id': 100,
                  'message_id': 4,
                  'file_name': 'photo.jpg',
                  'file_path': 'qna/user-123/4/photo.jpg',
                  'file_type': 'image/jpeg',
                  'file_size': 2048,
                  'created_at': '2025-06-01T10:00:00.000Z',
                },
              ],
            },
          ],
          'qna_attachments': [
            {
              'id': 100,
              'message_id': 4,
              'file_name': 'photo.jpg',
              'file_path': 'qna/user-123/4/photo.jpg',
              'file_type': 'image/jpeg',
              'file_size': 2048,
              'created_at': '2025-06-01T10:00:00.000Z',
            },
          ],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: '파일 첨부 메시지',
          attachments: [
            {
              'file_name': 'photo.jpg',
              'file_path': 'qna/user-123/4/photo.jpg',
              'file_type': 'image/jpeg',
              'file_size': 2048,
            },
          ],
        );

        expect(result, isA<QnaMessage>());
        expect(result.id, 4);
        // The refetched message should contain attachments
        expect(result.attachments.length, 1);
        expect(result.attachments[0].fileName, 'photo.jpg');

        tearDownMockSupabase();
      });

      test('여러 첨부파일과 함께 메시지를 생성한다', () async {
        setupMockSupabase({
          'qna_messages': [
            {
              'id': 5,
              'thread_id': 10,
              'user_id': 'user-123',
              'content': '여러 파일 첨부',
              'created_at': '2025-06-01T10:00:00.000Z',
              'is_admin_message': false,
              'qna_attachments': [
                {
                  'id': 200,
                  'message_id': 5,
                  'file_name': 'file1.jpg',
                  'file_path': 'qna/user-123/5/file1.jpg',
                  'file_type': 'image/jpeg',
                  'file_size': 1024,
                  'created_at': '2025-06-01T10:00:00.000Z',
                },
                {
                  'id': 201,
                  'message_id': 5,
                  'file_name': 'file2.pdf',
                  'file_path': 'qna/user-123/5/file2.pdf',
                  'file_type': 'application/pdf',
                  'file_size': 4096,
                  'created_at': '2025-06-01T10:01:00.000Z',
                },
              ],
            },
          ],
          'qna_attachments': <Map<String, dynamic>>[],
        });
        repository = QaRepository(client: testSupabaseClient!);

        final result = await repository.createQaMessage(
          threadId: 10,
          userId: 'user-123',
          content: '여러 파일 첨부',
          attachments: [
            {
              'file_name': 'file1.jpg',
              'file_path': 'qna/user-123/5/file1.jpg',
              'file_type': 'image/jpeg',
              'file_size': 1024,
            },
            {
              'file_name': 'file2.pdf',
              'file_path': 'qna/user-123/5/file2.pdf',
              'file_type': 'application/pdf',
              'file_size': 4096,
            },
          ],
        );

        expect(result, isA<QnaMessage>());

        tearDownMockSupabase();
      });
    });

    group('getSignedUrl', () {
      test('서명된 URL을 반환한다', () async {
        setupMockSupabase({});
        repository = QaRepository(client: testSupabaseClient!);

        // The mock storage returns '{}' which will be the response
        // createSignedUrl in mock HTTP returns the storage path
        final url =
            await repository.getSignedUrl('qna/user-123/1/image.jpg');

        expect(url, isNotEmpty);

        tearDownMockSupabase();
      });

      test('다른 경로의 서명된 URL을 반환한다', () async {
        setupMockSupabase({});
        repository = QaRepository(client: testSupabaseClient!);

        final url =
            await repository.getSignedUrl('qna/user-456/2/document.pdf');

        expect(url, isNotEmpty);

        tearDownMockSupabase();
      });
    });
  });

  group('QaRepository - QaThreadWithMessages 헬퍼 클래스', () {
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
      expect(result.messages.length, equals(1));
    });

    test('빈 메시지 리스트로 생성할 수 있다', () {
      final thread = QnaThread(
        id: 2,
        userId: 'user-456',
        title: '빈 스레드',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final result = QaThreadWithMessages(
        thread: thread,
        messages: [],
      );

      expect(result.messages, isEmpty);
    });

    test('여러 메시지가 있는 스레드를 생성할 수 있다', () {
      final now = DateTime.now();
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '문의',
        createdAt: now,
        updatedAt: now,
        status: 'IN_PROGRESS',
      );

      final messages = List.generate(
        5,
        (i) => QnaMessage(
          id: i + 1,
          threadId: 1,
          userId: i % 2 == 0 ? 'user-123' : 'admin-001',
          content: '메시지 $i',
          createdAt: now.add(Duration(minutes: i)),
          isAdminMessage: i % 2 != 0,
        ),
      );

      final result = QaThreadWithMessages(
        thread: thread,
        messages: messages,
      );

      expect(result.messages.length, 5);
      expect(result.messages.where((m) => m.isAdminMessage).length, 2);
      expect(result.messages.where((m) => !m.isAdminMessage).length, 3);
      expect(result.thread.status, 'IN_PROGRESS');
    });

    test('스레드의 상태 확장 메서드가 올바르게 동작한다', () {
      final now = DateTime.now();
      final receivedThread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '문의',
        createdAt: now,
        updatedAt: now,
        status: 'RECEIVED',
      );

      final result = QaThreadWithMessages(
        thread: receivedThread,
        messages: [],
      );

      expect(result.thread.isReceived, isTrue);
      expect(result.thread.isOpen, isTrue);
      expect(result.thread.isClosed, isFalse);
    });
  });

  group('QnaThread 모델 파싱', () {
    test('유효한 JSON에서 QnaThread를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'title': '문의 제목',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(json);

      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-123'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('RECEIVED'));
      expect(
          thread.createdAt, equals(DateTime.parse('2025-06-01T10:00:00.000Z')));
    });

    test('toJson으로 다시 JSON 변환이 가능하다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '문의',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-01T12:00:00.000Z'),
        status: 'IN_PROGRESS',
      );

      final json = thread.toJson();
      expect(json['id'], equals(1));
      expect(json['user_id'], equals('user-123'));
      expect(json['status'], equals('IN_PROGRESS'));
    });

    test('copyWith으로 상태를 변경할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '원래 제목',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final modified = thread.copyWith(status: 'RESOLVED');
      expect(modified.status, equals('RESOLVED'));
      expect(modified.title, equals('원래 제목'));
    });

    test('동일한 값을 가진 두 QnaThread는 같다', () {
      final dateTime = DateTime.parse('2025-06-01T10:00:00.000Z');
      final thread1 = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '동일',
        createdAt: dateTime,
        updatedAt: dateTime,
        status: 'RECEIVED',
      );
      final thread2 = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '동일',
        createdAt: dateTime,
        updatedAt: dateTime,
        status: 'RECEIVED',
      );
      expect(thread1, equals(thread2));
    });
  });

  group('QnaThread 상태 확장 메서드', () {
    late QnaThread receivedThread;
    late QnaThread inProgressThread;
    late QnaThread resolvedThread;

    setUp(() {
      final now = DateTime.now();
      receivedThread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '접수됨',
        createdAt: now,
        updatedAt: now,
        status: 'RECEIVED',
      );
      inProgressThread = receivedThread.copyWith(status: 'IN_PROGRESS');
      resolvedThread = receivedThread.copyWith(status: 'RESOLVED');
    });

    test('RECEIVED 상태일 때 isReceived가 true이다', () {
      expect(receivedThread.isReceived, isTrue);
      expect(receivedThread.isInProgress, isFalse);
      expect(receivedThread.isResolved, isFalse);
    });

    test('IN_PROGRESS 상태일 때 isInProgress가 true이다', () {
      expect(inProgressThread.isReceived, isFalse);
      expect(inProgressThread.isInProgress, isTrue);
      expect(inProgressThread.isResolved, isFalse);
    });

    test('RESOLVED 상태일 때 isResolved가 true이다', () {
      expect(resolvedThread.isReceived, isFalse);
      expect(resolvedThread.isInProgress, isFalse);
      expect(resolvedThread.isResolved, isTrue);
    });

    test('RECEIVED/IN_PROGRESS 상태는 isOpen이 true이다', () {
      expect(receivedThread.isOpen, isTrue);
      expect(inProgressThread.isOpen, isTrue);
    });

    test('RESOLVED 상태는 isClosed가 true이다', () {
      expect(resolvedThread.isClosed, isTrue);
      expect(resolvedThread.isOpen, isFalse);
    });
  });

  group('QnaMessage 모델 파싱', () {
    test('유효한 JSON에서 QnaMessage를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '안녕하세요, 문의드립니다.',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);

      expect(message.id, equals(1));
      expect(message.threadId, equals(10));
      expect(message.userId, equals('user-123'));
      expect(message.content, equals('안녕하세요, 문의드립니다.'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments, isEmpty);
    });

    test('첨부파일이 포함된 JSON을 파싱할 수 있다', () {
      final json = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '첨부파일 포함 메시지',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 1,
            'message_id': 2,
            'file_name': 'screenshot.png',
            'file_path': 'qna/user-123/2/screenshot.png',
            'file_type': 'image/png',
            'file_size': 1024,
            'created_at': '2025-06-01T10:00:00.000Z',
          },
        ],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments.length, equals(1));
      expect(message.attachments[0].fileName, equals('screenshot.png'));
      expect(message.attachments[0].fileType, equals('image/png'));
    });

    test('관리자 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 3,
        'thread_id': 10,
        'user_id': 'admin-001',
        'content': '답변드립니다.',
        'created_at': '2025-06-01T11:00:00.000Z',
        'is_admin_message': true,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.isAdminMessage, isTrue);
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

    test('toJson으로 JSON 변환이 가능하다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final json = message.toJson();
      expect(json['id'], equals(1));
      expect(json['thread_id'], equals(10));
      expect(json['user_id'], equals('user-123'));
      expect(json['is_admin_message'], isFalse);
    });

    test('copyWith으로 content를 변경할 수 있다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '원래 내용',
        createdAt: DateTime.now(),
        isAdminMessage: false,
      );

      final updated = message.copyWith(content: '수정된 내용');
      expect(updated.content, '수정된 내용');
      expect(updated.id, 1);
      expect(updated.threadId, 10);
    });

    test('동일한 값을 가진 두 QnaMessage는 같다', () {
      final dt = DateTime.parse('2025-06-01T10:00:00.000Z');
      final msg1 = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '같은 내용',
        createdAt: dt,
        isAdminMessage: false,
      );
      final msg2 = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '같은 내용',
        createdAt: dt,
        isAdminMessage: false,
      );
      expect(msg1, equals(msg2));
    });
  });
}
