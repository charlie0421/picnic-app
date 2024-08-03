import 'package:picnic_app/config/environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final supabase =
    SupabaseClient(Environment.supabaseUrl, Environment.supabaseAnonKey);

final supabaseStorage = SupabaseClient(
    Environment.supabaseStorageUrl, Environment.supabaseStorageAnonKey);
