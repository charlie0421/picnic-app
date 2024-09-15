import 'package:http/http.dart' as http;
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/storage/supabase_pkce_async_storage.dart';
import 'package:picnic_app/util/network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customHttpClient = RetryHttpClient(http.Client());

final supabase = SupabaseClient(
    Environment.supabaseUrl, Environment.supabaseAnonKey,
    authOptions: AuthClientOptions(
        authFlowType: AuthFlowType.pkce, pkceAsyncStorage: PlatformStorage()));

final supabaseStorage = SupabaseClient(
    Environment.supabaseStorageUrl, Environment.supabaseStorageAnonKey);
