import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PopupRepository {
  final _client = Supabase.instance.client;

  Future<List<Popup>> fetchPopups() async {
    final response = await _client
        .from('popup')
        .select()
        .lte('start_at', DateTime.now().toIso8601String())
        .gte('stop_at', DateTime.now().toIso8601String())
        .filter('deleted_at', 'is', null)
        .order('start_at', ascending: true);

    return (response as List)
        .map((e) => Popup.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
