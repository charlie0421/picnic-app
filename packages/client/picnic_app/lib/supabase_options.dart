import 'package:flutter_config/flutter_config.dart';
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
    url: FlutterConfig.get('SUPABASE_URL'),
    anonKey: FlutterConfig.get('SUPABASE_ANON_KEY'));
final supabase = SupabaseClient(supabaseOptions.url, supabaseOptions.anonKey);
