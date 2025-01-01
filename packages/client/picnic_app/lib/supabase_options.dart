import 'package:http/http.dart' as http;
import 'package:picnic_app/core/config/environment.dart';
import 'package:picnic_app/core/utils/retry_http_client.dart';
import 'package:picnic_app/data/storage/supabase_pkce_async_storage.dart';
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

// 클라이언트 인스턴스 가져오기
final supabase = Supabase.instance.client;

final supabaseStorage = SupabaseClient(
  Environment.supabaseStorageUrl,
  Environment.supabaseStorageAnonKey,
  httpClient: customHttpClient,
  headers: {
    'Accept-Charset': 'utf-8',
  },
);
