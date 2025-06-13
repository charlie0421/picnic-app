import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:picnic_lib/data/storage/supabase_pkce_async_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customHttpClient = RetryHttpClient(http.Client());

// Supabase 초기화를 위한 함수
Future<void> initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: PlatformStorage(),
      ),
      httpClient: customHttpClient,
    );
    
    // 초기화 완료 후 클라이언트 상태 확인
    final client = Supabase.instance.client;
    print('Supabase 초기화 완료 - URL: ${Environment.supabaseUrl}');
    
  } catch (e) {
    print('Supabase 초기화 실패: $e');
    print('URL: ${Environment.supabaseUrl}');
    print('Key length: ${Environment.supabaseAnonKey.length}');
    rethrow;
  }
}

// 안전한 클라이언트 인스턴스 getter
SupabaseClient get supabase {
  try {
    return Supabase.instance.client;
  } catch (e) {
    throw StateError('Supabase가 초기화되지 않았습니다. initializeSupabase()를 먼저 호출하세요. 에러: $e');
  }
}

// 안전한 로그인 상태 확인 함수
bool get isSupabaseLoggedSafely {
  try {
    return supabase.auth.currentUser != null;
  } catch (e) {
    // Supabase가 초기화되지 않았거나 에러가 발생한 경우 false 반환
    return false;
  }
}

final supabaseStorage = SupabaseClient(
  Environment.supabaseStorageUrl,
  Environment.supabaseStorageAnonKey,
  httpClient: customHttpClient,
  headers: {
    'Accept-Charset': 'utf-8',
  },
);
