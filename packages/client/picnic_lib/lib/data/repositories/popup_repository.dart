import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PopupRepository {
  final _client = Supabase.instance.client;

  Future<List<Popup>> fetchPopups() async {
    final response = await _client
        .from('popup')
        .select()
        .order('start_at', ascending: false);
    return (response as List)
        .map((e) => Popup.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
