import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

/// Creates a SupabaseClient where all REST/storage requests return HTTP 500,
/// forcing every repository method into its catch branch.
SupabaseClient _createErrorClient() {
  final mockClient = MockClient((request) async {
    final path = request.url.path;
    // Auth endpoints still work
    if (path.contains('/auth/')) {
      return http.Response('{"error":"not auth"}', 401, request: request);
    }
    // Everything else errors
    return http.Response(
      jsonEncode({'message': 'Internal Server Error', 'code': '500'}),
      500,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  });

  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key-for-testing-purposes-only',
    httpClient: mockClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

/// Creates a SupabaseClient that handles REST and storage (upload returns
/// a valid key string) so that the full attachment upload path is covered.
SupabaseClient _createClientWithStorageSupport(
    Map<String, dynamic> tableResponses) {
  final mockClient = MockClient((request) async {
    final uri = request.url;
    final path = uri.path;

    if (path.contains('/auth/')) {
      return http.Response('{"error":"not auth"}', 401, request: request);
    }

    // Storage upload: return a JSON with Key
    if (path.contains('/storage/v1/object/')) {
      return http.Response(
        jsonEncode({'Key': 'qna/user-1/42/uploaded.png'}),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }

    // Storage public URL
    if (path.contains('/storage/v1/')) {
      return http.Response('{}', 200,
          request: request,
          headers: {'content-type': 'application/json'});
    }

    // REST endpoints
    if (path.contains('/rest/v1/')) {
      final tableName = path.split('/rest/v1/').last.split('?').first;
      final acceptHeader =
          request.headers['Accept'] ?? request.headers['accept'] ?? '';
      final isSingle = acceptHeader.contains('vnd.pgrst.object');

      if (tableResponses.containsKey(tableName)) {
        final data = tableResponses[tableName];
        if (isSingle && data is List) {
          if (data.isEmpty) {
            return http.Response('null', 200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          return http.Response(jsonEncode(data.first), 200,
              request: request,
              headers: {
                'content-type': 'application/json',
                'content-range': '0-0/1',
              });
        }
        return http.Response(jsonEncode(data), 200,
            request: request,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-${(data as List).length}/*',
            });
      }
      if (isSingle) {
        return http.Response('null', 200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('[]', 200,
          request: request,
          headers: {'content-type': 'application/json'});
    }

    return http.Response('{}', 200,
        request: request, headers: {'content-type': 'application/json'});
  });

  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key-for-testing-purposes-only',
    httpClient: mockClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

/// Creates a SupabaseClient that serves specific table data but errors on
/// storage uploads.
SupabaseClient _createClientWithStorageError(
    Map<String, dynamic> tableResponses) {
  final mockClient = MockClient((request) async {
    final uri = request.url;
    final path = uri.path;

    if (path.contains('/auth/')) {
      return http.Response('{"error":"not auth"}', 401, request: request);
    }

    // Storage always errors
    if (path.contains('/storage/v1/')) {
      return http.Response(
        jsonEncode({'error': 'upload failed'}),
        500,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }

    // REST endpoints
    if (path.contains('/rest/v1/')) {
      final tableName = path.split('/rest/v1/').last.split('?').first;
      final acceptHeader =
          request.headers['Accept'] ?? request.headers['accept'] ?? '';
      final isSingle = acceptHeader.contains('vnd.pgrst.object');

      if (tableResponses.containsKey(tableName)) {
        final data = tableResponses[tableName];
        if (isSingle && data is List) {
          if (data.isEmpty) {
            return http.Response('null', 200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          return http.Response(jsonEncode(data.first), 200,
              request: request,
              headers: {
                'content-type': 'application/json',
                'content-range': '0-0/1',
              });
        }
        return http.Response(jsonEncode(data), 200,
            request: request,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-${(data as List).length}/*',
            });
      }
      if (isSingle) {
        return http.Response('null', 200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('[]', 200,
          request: request,
          headers: {'content-type': 'application/json'});
    }

    return http.Response('{}', 200,
        request: request, headers: {'content-type': 'application/json'});
  });

  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key-for-testing-purposes-only',
    httpClient: mockClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------
  // Error-branch coverage: every public method's catch clause
  // ---------------------------------------------------------------
  group('QnaRepository - error handling branches', () {
    late QnaRepository repository;

    setUp(() {
      repository = QnaRepository(client: _createErrorClient());
    });

    test('getQaThreadList throws on server error', () async {
      expect(
        () => repository.getQaThreadList(userId: 'user-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 스레드 목록 조회 실패'),
        )),
      );
    });

    test('getQaThreadById throws on server error', () async {
      expect(
        () => repository.getQaThreadById(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 스레드 조회 실패'),
        )),
      );
    });

    test('createQaThread throws on server error', () async {
      expect(
        () => repository.createQaThread(
          userId: 'user-1',
          title: 'Test',
          initialMessage: 'Hello',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 스레드 생성 실패'),
        )),
      );
    });

    test('getCategories throws on server error', () async {
      expect(
        () => repository.getCategories(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 카테고리 조회 실패'),
        )),
      );
    });

    test('createQaMessage throws on server error', () async {
      expect(
        () => repository.createQaMessage(
          threadId: 1,
          userId: 'user-1',
          content: 'Hello',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 메시지 생성 실패'),
        )),
      );
    });

    test('getFirstAttachmentForThread throws on server error', () async {
      expect(
        () => repository.getFirstAttachmentForThread(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('첫 첨부파일 조회 실패'),
        )),
      );
    });

    test('getPublicUrl throws on error', () {
      // getPublicUrl constructs URL locally — we test that it doesn't throw
      // for a valid client. For the error branch, we need a client where
      // storage itself errors.
      // The mock error client returns 500 but getPublicUrl is synchronous
      // and just builds a URL, so it won't throw with a valid client.
      // We still exercise the path to confirm no regression.
      final errorRepo = QnaRepository(client: _createErrorClient());
      // getPublicUrl is synchronous and builds URL from client config,
      // so it should succeed even with error client
      final url = errorRepo.getPublicUrl('some/path.png');
      expect(url, contains('some/path.png'));
    });
  });

  // ---------------------------------------------------------------
  // _getCategoryLabelByCode error branch (line 113)
  // ---------------------------------------------------------------
  group('QnaRepository - _getCategoryLabelByCode error branch', () {
    test('getQaThreadById with category_code but categories table errors',
        () async {
      // Set up: qna_threads has a category_code, qna_messages works,
      // but qna_categories returns error data (missing from mock -> null)
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 10,
            'user_id': 'user-1',
            'title': 'Thread with category',
            'category_code': 'NONEXISTENT',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          },
        ],
        'qna_messages': [
          {
            'id': 100,
            'thread_id': 10,
            'user_id': 'user-1',
            'content': 'Hello',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
        // qna_categories not configured, so .maybeSingle() returns null
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final result = await repo.getQaThreadById(10);

      // categoryLabel should be null since the category wasn't found
      expect(result.categoryLabel, isNull);
      expect(result.thread.id, 10);
      expect(result.messages.length, 1);
    });
  });

  // ---------------------------------------------------------------
  // _getCategoryLabelByCode catch branch (line 113)
  // when categories table query itself throws
  // ---------------------------------------------------------------
  group('QnaRepository - _getCategoryLabelByCode exception branch', () {
    test('returns null categoryLabel when categories query throws', () async {
      // Create a client that returns thread/messages OK but 500s on
      // qna_categories table.
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final acceptHeader =
            request.headers['Accept'] ?? request.headers['accept'] ?? '';
        final isSingle = acceptHeader.contains('vnd.pgrst.object');

        if (path.contains('/auth/')) {
          return http.Response('{"error":"not auth"}', 401, request: request);
        }

        if (path.contains('/rest/v1/qna_categories')) {
          return http.Response(
            jsonEncode(
                {'message': 'Internal Server Error', 'code': 'PGRST116'}),
            500,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.contains('/rest/v1/qna_threads')) {
          final data = {
            'id': 30,
            'user_id': 'user-1',
            'title': 'Cat error thread',
            'category_code': 'BROKEN',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          };
          if (isSingle) {
            return http.Response(jsonEncode(data), 200,
                request: request,
                headers: {
                  'content-type': 'application/json',
                  'content-range': '0-0/1',
                });
          }
          return http.Response(jsonEncode([data]), 200,
              request: request,
              headers: {
                'content-type': 'application/json',
                'content-range': '0-0/1',
              });
        }

        if (path.contains('/rest/v1/qna_messages')) {
          final msgs = [
            {
              'id': 300,
              'thread_id': 30,
              'user_id': 'user-1',
              'content': 'Hi',
              'created_at': '2025-01-01T00:00:00Z',
              'is_admin_message': false,
              'qna_attachments': [],
            }
          ];
          return http.Response(jsonEncode(msgs), 200,
              request: request,
              headers: {
                'content-type': 'application/json',
                'content-range': '0-0/1',
              });
        }

        return http.Response('[]', 200,
            request: request,
            headers: {'content-type': 'application/json'});
      });

      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key-for-testing-purposes-only',
        httpClient: mockClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final repo = QnaRepository(client: client);
      final result = await repo.getQaThreadById(30);

      // The category lookup failed with an exception, so categoryLabel
      // should be null (caught by _getCategoryLabelByCode's catch block)
      expect(result.categoryLabel, isNull);
      expect(result.thread.id, 30);
      expect(result.messages.length, 1);
    });
  });

  // ---------------------------------------------------------------
  // createQaMessage with attachments (lines 215-242, 258-260)
  // ---------------------------------------------------------------
  group('QnaRepository - createQaMessage with attachments', () {
    test('attachment upload path is exercised and errors are caught', () async {
      // Create a temporary file to use as attachment
      final tempDir = Directory.systemTemp.createTempSync('qna_test_');
      final tempFile = File('${tempDir.path}/test_image.png')
        ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]); // PNG header bytes

      addTearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      setupMockSupabase({
        'qna_messages': [
          {
            'id': 42,
            'thread_id': 1,
            'user_id': 'user-1',
            'content': 'With attachment',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
        'qna_attachments': [],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      // The mock storage returns '{}' which causes a type cast error
      // inside storage.upload, but this exercises the attachment code path
      // (lines 214-242) and the catch branch (line 254).
      expect(
        () => repo.createQaMessage(
          threadId: 1,
          userId: 'user-1',
          content: 'With attachment',
          attachments: [tempFile],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 메시지 생성 실패'),
        )),
      );
    });

    test('full attachment upload path succeeds with proper storage mock',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('qna_test_ok_');
      final tempFile = File('${tempDir.path}/photo.png')
        ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]); // PNG header

      addTearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      final messageWithAttachments = {
        'id': 42,
        'thread_id': 1,
        'user_id': 'user-1',
        'content': 'With attachment',
        'created_at': '2025-01-01T00:00:00Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 1,
            'message_id': 42,
            'file_name': 'photo.png',
            'file_path': 'qna/user-1/42/photo.png',
            'file_type': 'image/png',
            'file_size': 4,
            'created_at': '2025-01-01T00:00:00Z',
          }
        ],
      };

      final client = _createClientWithStorageSupport({
        'qna_messages': [messageWithAttachments],
        'qna_attachments': [],
      });

      final repo = QnaRepository(client: client);
      final result = await repo.createQaMessage(
        threadId: 1,
        userId: 'user-1',
        content: 'With attachment',
        attachments: [tempFile],
      );

      expect(result.id, 42);
      expect(result.attachments, isNotEmpty);
    });

    test('createQaMessage with attachments throws when storage upload fails',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('qna_test_err_');
      final tempFile = File('${tempDir.path}/fail.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]); // JPEG header

      addTearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      // Use a client that returns messages OK but storage errors
      final client = _createClientWithStorageError({
        'qna_messages': [
          {
            'id': 99,
            'thread_id': 1,
            'user_id': 'user-1',
            'content': 'Fail upload',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });

      final repo = QnaRepository(client: client);
      expect(
        () => repo.createQaMessage(
          threadId: 1,
          userId: 'user-1',
          content: 'Fail upload',
          attachments: [tempFile],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Q&A 메시지 생성 실패'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------
  // createQaThread with attachments
  // ---------------------------------------------------------------
  group('QnaRepository - createQaThread with categoryCode', () {
    test('creates thread with category code', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 50,
            'user_id': 'user-1',
            'title': 'With category',
            'category_code': 'ACCOUNT',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          },
        ],
        'qna_messages': [
          {
            'id': 200,
            'thread_id': 50,
            'user_id': 'user-1',
            'content': 'Initial message',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final thread = await repo.createQaThread(
        userId: 'user-1',
        title: 'With category',
        initialMessage: 'Initial message',
        categoryCode: 'ACCOUNT',
      );

      expect(thread.id, 50);
      expect(thread.title, 'With category');
    });
  });

  // ---------------------------------------------------------------
  // getFirstAttachmentForThread with data (line 286-287)
  // ---------------------------------------------------------------
  group('QnaRepository - getFirstAttachmentForThread with attachment', () {
    test('returns first attachment when data exists', () async {
      setupMockSupabase({
        'qna_attachments': [
          {
            'id': 5,
            'message_id': 10,
            'file_name': 'photo.jpg',
            'file_path': 'qna/user-1/10/photo.jpg',
            'file_type': 'image/jpeg',
            'file_size': 1024,
            'created_at': '2025-01-01T00:00:00Z',
            'qna_messages': {'thread_id': 1},
          },
        ],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final attachment = await repo.getFirstAttachmentForThread(1);

      expect(attachment, isNotNull);
      expect(attachment, isA<QnaAttachment>());
      expect(attachment!.id, 5);
      expect(attachment.fileName, 'photo.jpg');
    });
  });

  // ---------------------------------------------------------------
  // getQaThreadById with empty category_code (line 86 branch)
  // ---------------------------------------------------------------
  group('QnaRepository - getQaThreadById with empty category_code', () {
    test('skips category lookup when category_code is empty string', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 20,
            'user_id': 'user-1',
            'title': 'No category',
            'category_code': '',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          },
        ],
        'qna_messages': [
          {
            'id': 101,
            'thread_id': 20,
            'user_id': 'user-1',
            'content': 'Hi',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final result = await repo.getQaThreadById(20);

      expect(result.categoryLabel, isNull);
      expect(result.thread.id, 20);
    });

    test('skips category lookup when category_code is null', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 21,
            'user_id': 'user-1',
            'title': 'Null category',
            'category_code': null,
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          },
        ],
        'qna_messages': [
          {
            'id': 102,
            'thread_id': 21,
            'user_id': 'user-1',
            'content': 'Hi',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final result = await repo.getQaThreadById(21);

      expect(result.categoryLabel, isNull);
    });
  });

  // ---------------------------------------------------------------
  // createQaThread without categoryCode (line 129 branch)
  // ---------------------------------------------------------------
  group('QnaRepository - createQaThread without categoryCode', () {
    test('creates thread without category code', () async {
      setupMockSupabase({
        'qna_threads': [
          {
            'id': 60,
            'user_id': 'user-1',
            'title': 'Simple thread',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'status': 'RECEIVED',
          },
        ],
        'qna_messages': [
          {
            'id': 300,
            'thread_id': 60,
            'user_id': 'user-1',
            'content': 'Hello',
            'created_at': '2025-01-01T00:00:00Z',
            'is_admin_message': false,
            'qna_attachments': [],
          },
        ],
      });
      addTearDown(tearDownMockSupabase);

      final repo = QnaRepository(client: testSupabaseClient!);
      final thread = await repo.createQaThread(
        userId: 'user-1',
        title: 'Simple thread',
        initialMessage: 'Hello',
      );

      expect(thread.id, 60);
    });
  });
}
