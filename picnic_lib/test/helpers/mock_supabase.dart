import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/supabase_options.dart';

/// 테스트용 가짜 JWT 생성
String _createFakeJwt(String userId) {
  String base64UrlEncode(String input) {
    return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  }
  final header = base64UrlEncode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
  final payload = base64UrlEncode(jsonEncode({
    'sub': userId,
    'email': 'test@test.com',
    'aud': 'authenticated',
    'role': 'authenticated',
    'exp': (DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch / 1000).floor(),
    'iat': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
  }));
  final signature = base64UrlEncode('fake-signature');
  return '$header.$payload.$signature';
}

/// 마지막 setup 이후 mock 클라이언트가 받은 요청 URI 기록.
///
/// 이 하네스는 `.eq()` 필터를 무시하고 테이블 픽스처 전체를 돌려주므로,
/// "쿼리가 사용자로 스코핑되는가" 같은 보안 속성은 응답만으로는 테스트할 수
/// 없다. 그런 속성은 여기 기록된 URI 의 쿼리 파라미터
/// (예: `user_id=eq.<uid>`) 를 단언해서 와이어 레벨로 고정한다.
final List<Uri> capturedMockRequests = [];

/// Supabase 테스트용 Mock HTTP 응답 설정
///
/// 사용법:
/// ```dart
/// setUp(() {
///   setupMockSupabase({
///     'reward': [{'id': 1, 'title': {'ko': '보상'}}],
///     'banner': [{'id': 1, 'title': {'ko': '배너'}}],
///   });
/// });
/// tearDown(() => tearDownMockSupabase());
/// ```
void setupMockSupabase(Map<String, dynamic> tableResponses, {
  String? userId,
  Map<String, int>? functionStatusCodes,
  Map<String, int>? tableStatusCodes,
}) {
  _setupClient(tableResponses, userId: userId, functionStatusCodes: functionStatusCodes, tableStatusCodes: tableStatusCodes);
}

/// 인증된 사용자 세션을 포함한 Mock Supabase 설정 (비동기)
///
/// isSupabaseLoggedSafely가 true를 반환해야 하는 테스트에 사용:
/// ```dart
/// setUp(() async {
///   await setupMockSupabaseWithAuth({...}, userId: 'test-user-id');
/// });
/// ```
Future<void> setupMockSupabaseWithAuth(Map<String, dynamic> tableResponses, {
  required String userId,
  Map<String, int>? functionStatusCodes,
  Map<String, int>? tableStatusCodes,
}) async {
  _setupClient(tableResponses, userId: userId, functionStatusCodes: functionStatusCodes, tableStatusCodes: tableStatusCodes);

  // 인증된 세션 설정
  try {
    await testSupabaseClient!.auth.signInWithPassword(
      email: 'test@test.com',
      password: 'fake-password',
    );
  } catch (_) {
    // mock이 올바른 응답을 반환하면 세션이 설정됨
  }
}

void _setupClient(Map<String, dynamic> tableResponses, {
  String? userId,
  Map<String, int>? functionStatusCodes,
  Map<String, int>? tableStatusCodes,
}) {
  final fakeJwt = userId != null ? _createFakeJwt(userId) : null;
  capturedMockRequests.clear();

  final mockClient = MockClient((request) async {
    final uri = request.url;
    final path = uri.path;
    capturedMockRequests.add(uri);

    // Auth endpoints
    if (path.contains('/auth/')) {
      if (userId != null) {
        // Token endpoint (sign-in, refresh)
        if (path.contains('/token') || path.contains('/user')) {
          return http.Response(
            jsonEncode({
              'access_token': fakeJwt,
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'fake-refresh-token',
              'user': {
                'id': userId,
                'email': 'test@test.com',
                'aud': 'authenticated',
                'role': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': DateTime.now().toIso8601String(),
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'id': userId,
            'email': 'test@test.com',
            'aud': 'authenticated',
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"error": "not authenticated"}', 401, request: request);
    }

    // Edge Functions
    if (path.contains('/functions/v1/')) {
      final funcName = path.split('/functions/v1/').last;
      final method = request.method.toUpperCase();
      // Support method-specific keys like 'functions:attendance-check:POST'
      final methodKey = 'functions:$funcName:$method';
      final genericKey = 'functions:$funcName';

      final responseKey = tableResponses.containsKey(methodKey) ? methodKey : genericKey;

      if (tableResponses.containsKey(responseKey)) {
        final statusCodeKey = tableResponses.containsKey(methodKey) ? methodKey : genericKey;
        final statusCode = functionStatusCodes?[statusCodeKey] ?? 200;
        return http.Response(
          jsonEncode(tableResponses[responseKey]),
          statusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': true, 'data': {}}),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }

    // REST endpoints (table queries)
    if (path.contains('/rest/v1/')) {
      final tableName = path.split('/rest/v1/').last.split('?').first;
      final acceptHeader = request.headers['Accept'] ?? request.headers['accept'] ?? '';
      final isSingle = acceptHeader.contains('vnd.pgrst.object');

      // Check if this table should return an error status code
      final tableStatusCode = tableStatusCodes?[tableName];
      if (tableStatusCode != null && tableStatusCode >= 400) {
        return http.Response(
          jsonEncode({'message': 'Mock error for table $tableName', 'code': 'PGRST000'}),
          tableStatusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }

      if (tableResponses.containsKey(tableName)) {
        final data = tableResponses[tableName];
        // .single() / .maybeSingle() sends Accept: application/vnd.pgrst.object+json
        if (isSingle && data is List) {
          if (data.isEmpty) {
            return http.Response(
              'null',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(data.first),
            200,
            request: request,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-0/1',
            },
          );
        }
        return http.Response(
          jsonEncode(data),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-${(data as List).length}/*',
          },
        );
      }
      if (isSingle) {
        return http.Response('null', 200, request: request, headers: {'content-type': 'application/json'});
      }
      return http.Response('[]', 200, request: request, headers: {'content-type': 'application/json'});
    }

    // Storage
    if (path.contains('/storage/v1/')) {
      return http.Response('{}', 200, request: request, headers: {'content-type': 'application/json'});
    }

    // Default
    return http.Response('{}', 200, request: request, headers: {'content-type': 'application/json'});
  });

  testSupabaseClient = SupabaseClient(
    'http://localhost:54321',
    'test-anon-key-for-testing-purposes-only',
    httpClient: mockClient,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
    ),
  );
}

/// Mock Supabase 정리
void tearDownMockSupabase() {
  testSupabaseClient = null;
  capturedMockRequests.clear();
}
