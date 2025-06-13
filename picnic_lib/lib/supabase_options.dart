import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:picnic_lib/data/storage/supabase_pkce_async_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customHttpClient = RetryHttpClient(http.Client());

// Supabase 초기화를 위한 함수
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      pkceAsyncStorage: PlatformStorage(),
    ),
    httpClient: customHttpClient,
  );
}

// 안전한 클라이언트 인스턴스 getter
SupabaseClient get supabase {
  try {
    return Supabase.instance.client;
  } catch (e) {
    throw StateError('Supabase not initialized. Call initializeSupabase() first. Error: $e');
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
