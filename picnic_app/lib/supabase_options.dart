import 'package:picnic_app/util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final SupabaseOptions supabaseOptions = SupabaseOptions(
    url: getEnv('SUPABASE_URL'), anonKey: getEnv('SUPABASE_ANON_KEY'));
final supabase = SupabaseClient(supabaseOptions.url, supabaseOptions.anonKey);
