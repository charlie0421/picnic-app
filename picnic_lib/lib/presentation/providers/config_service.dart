import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/config_service.g.dart';

class ConfigService {
  final SupabaseClient _supabase;

  ConfigService(this._supabase);

  Future<String?> getConfig(String key) async {
    try {
      final response = await _supabase
          .from('config')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      return response?['value'] as String?;
    } catch (e, s) {
      logger.e('Error fetching config: $e, $s');
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return null;
    }
  }

  Stream<String?> streamConfig(String key) {
    return _supabase
        .from('config')
        .stream(primaryKey: ['key'])
        .eq('key', key)
        .map((event) =>
            event.isNotEmpty ? event.first['value'] as String? : null);
  }
}

@Riverpod(keepAlive: true)
ConfigService configService(Ref ref) {
  return ConfigService(supabase);
}
