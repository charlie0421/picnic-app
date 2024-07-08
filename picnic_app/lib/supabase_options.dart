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
  url: const String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://api.picnic.fan'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0aWp0ZWZjeWNvZXFsdWRsbmdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU4OTEyNzQsImV4cCI6MjAzMTQ2NzI3NH0.k0Viu8kgOnkJ7-tnrDTmqpe6TdtZCYkqmH_5vUvcv_k'),
);
final supabase = SupabaseClient(supabaseOptions.url, supabaseOptions.anonKey);
