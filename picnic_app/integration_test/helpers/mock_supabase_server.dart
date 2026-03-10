/// Mock Supabase 서버
///
/// E2E 테스트에서 실제 Supabase 백엔드 대신 사용하는
/// Mock 응답 서버입니다. 테스트 시나리오별로 다른 응답을 제공합니다.
import 'dart:convert';
import 'dart:io';

/// 테스트 시나리오 열거형
///
/// 각 시나리오에 따라 Mock 서버의 응답이 달라집니다.
enum MockScenario {
  /// 기본 시나리오: 로그인된 사용자, 정상 데이터
  defaultScenario,

  /// 비로그인 시나리오: 인증되지 않은 상태
  unauthenticated,

  /// 네트워크 오류 시나리오: API 호출 시 에러 반환
  networkError,

  /// 빈 데이터 시나리오: 데이터가 없는 상태
  emptyData,

  /// 밴 사용자 시나리오: 차단된 사용자
  bannedUser,
}

/// Mock Supabase 서버 구현
///
/// 로컬 HTTP 서버를 실행하여 Supabase API 요청을 가로채고
/// 테스트 시나리오에 맞는 응답을 반환합니다.
class MockSupabaseServer {
  final MockScenario scenario;
  HttpServer? _server;

  /// Mock 서버의 기본 URL (서버 시작 후 설정됨)
  String get baseUrl => 'http://localhost:${_server?.port ?? 0}';

  MockSupabaseServer({this.scenario = MockScenario.defaultScenario});

  /// Mock 서버 시작
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  /// Mock 서버 정지
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// HTTP 요청 핸들러
  ///
  /// 요청 경로에 따라 적절한 Mock 응답을 반환합니다.
  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;

    // CORS 헤더 설정
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Content-Type', 'application/json');

    // 네트워크 오류 시나리오: 모든 요청에 500 반환
    if (scenario == MockScenario.networkError) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': 'Mock network error'}));
      request.response.close();
      return;
    }

    // 경로별 응답 라우팅
    if (path.contains('/auth/')) {
      _handleAuthRequest(request);
    } else if (path.contains('/rest/')) {
      _handleDataRequest(request);
    } else {
      _handleDefaultRequest(request);
    }
  }

  /// 인증 관련 요청 처리
  void _handleAuthRequest(HttpRequest request) {
    final path = request.uri.path;

    if (scenario == MockScenario.unauthenticated) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(jsonEncode({
        'error': 'unauthorized',
        'message': '인증되지 않은 사용자',
      }));
      request.response.close();
      return;
    }

    // 기본 인증 응답 (로그인 성공)
    if (path.contains('/token') || path.contains('/signup')) {
      request.response.write(jsonEncode(_mockAuthResponse()));
    } else if (path.contains('/user')) {
      request.response.write(jsonEncode(_mockUserResponse()));
    } else {
      request.response.write(jsonEncode({'status': 'ok'}));
    }

    request.response.close();
  }

  /// 데이터 쿼리 요청 처리
  void _handleDataRequest(HttpRequest request) {
    final path = request.uri.path;

    if (scenario == MockScenario.emptyData) {
      request.response.write(jsonEncode([]));
      request.response.close();
      return;
    }

    if (scenario == MockScenario.bannedUser) {
      request.response.write(jsonEncode({
        'is_banned': true,
        'ban_reason': 'Mock: 테스트 밴 사용자',
      }));
      request.response.close();
      return;
    }

    // TODO: 경로별 Mock 데이터 구현
    // 투표 데이터
    if (path.contains('/votes') || path.contains('/voting')) {
      request.response.write(jsonEncode(_mockVotesResponse()));
    }
    // 검색 결과
    else if (path.contains('/search')) {
      request.response.write(jsonEncode(_mockSearchResponse()));
    }
    // 사용자 프로필
    else if (path.contains('/profiles')) {
      request.response.write(jsonEncode(_mockProfileResponse()));
    }
    // 기본 응답
    else {
      request.response.write(jsonEncode([]));
    }

    request.response.close();
  }

  /// 기본 요청 처리
  void _handleDefaultRequest(HttpRequest request) {
    request.response.write(jsonEncode({'status': 'ok'}));
    request.response.close();
  }

  // === Mock 응답 데이터 ===

  /// Mock 인증 응답
  Map<String, dynamic> _mockAuthResponse() {
    return {
      'access_token': 'mock_access_token_for_e2e_test',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'mock_refresh_token_for_e2e_test',
      'user': _mockUserResponse(),
    };
  }

  /// Mock 사용자 응답
  Map<String, dynamic> _mockUserResponse() {
    return {
      'id': 'mock-user-id-12345',
      'email': 'test@picnic.com',
      'created_at': DateTime.now().toIso8601String(),
      'app_metadata': {'provider': 'kakao'},
      'user_metadata': {
        'nickname': '테스트유저',
        'avatar_url': '',
      },
    };
  }

  /// Mock 투표 데이터 응답
  List<Map<String, dynamic>> _mockVotesResponse() {
    return [
      {
        'id': 'vote-1',
        'title': '테스트 투표 1',
        'options': ['선택지 A', '선택지 B'],
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'vote-2',
        'title': '테스트 투표 2',
        'options': ['옵션 1', '옵션 2', '옵션 3'],
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  /// Mock 검색 결과 응답
  List<Map<String, dynamic>> _mockSearchResponse() {
    return [
      {
        'id': 'result-1',
        'title': '검색 결과 1',
        'type': 'vote',
      },
      {
        'id': 'result-2',
        'title': '검색 결과 2',
        'type': 'user',
      },
    ];
  }

  /// Mock 프로필 응답
  Map<String, dynamic> _mockProfileResponse() {
    return {
      'id': 'mock-user-id-12345',
      'nickname': '테스트유저',
      'avatar_url': '',
      'point': 1000,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
