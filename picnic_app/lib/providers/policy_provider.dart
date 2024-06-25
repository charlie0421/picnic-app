import 'package:picnic_app/models/policy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'policy_provider.g.dart';

@riverpod
class AsyncPolicy extends _$AsyncPolicy {
  @override
  Future<PolicyItemModel> build(
      {required PolicyType type, required PolicyLanguage language}) async {
    return _fetch(type: type, language: language);
  }

  Future<PolicyItemModel> _fetch(
      {required PolicyType type, required PolicyLanguage language}) async {
    final response = await Supabase.instance.client
        .from('policy')
        .select()
        .eq('type', type.name)
        .eq('language', language.name)
        .limit(1)
        .order('created_at', ascending: false)
        .single();
    return PolicyItemModel.fromJson(response);
  }
}
