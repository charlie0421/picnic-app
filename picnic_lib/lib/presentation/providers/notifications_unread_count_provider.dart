import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotificationsCountProvider = AutoDisposeFutureProvider<int>((
  ref,
) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return 0;
  try {
    final List<dynamic> rows = await client
        .from('user_notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false)
        .order('created_at', ascending: false)
        .limit(200);
    return rows.length;
  } catch (_) {
    return 0;
  }
});

