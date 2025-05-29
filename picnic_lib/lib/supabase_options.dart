import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/caching_http_client.dart';
import 'package:picnic_lib/data/storage/supabase_pkce_async_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customHttpClient = CachingHttpClient(http.Client());

// Supabase 초기화를 위한 함수
Future<void> initializeSupabase() async {
  // Initialize network service first
  await EnhancedNetworkService().initialize();

  // Initialize cache manager
  await SimpleCacheManager.instance.init();

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
