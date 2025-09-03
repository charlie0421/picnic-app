import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/policy_provider.g.dart';

// @riverpod
// class AsyncPolicy extends _$AsyncPolicy {
//   @override
//   Future<PolicyItemModel> build(
//       {required PolicyType type, required PolicyLanguage language}) async {
//     return _fetch(type: type, language: language);
//   }
//
//   Future<PolicyItemModel> _fetch(
//       {required PolicyType type, required PolicyLanguage language}) async {
//     final response = await supabase
//         .from('policy')
//         .select()
//         .eq('type', type.name)
//         .eq('language', language.name)
//         .limit(1)
//         .order('created_at', ascending: false)
//         .single();
//     return PolicyItemModel.fromJson(response);
//   }
// }

@riverpod
class AsyncPolicy extends _$AsyncPolicy {
  @override
  Future<PolicyModel> build() async {
    return _fetch();
  }

  Future<PolicyModel> _fetch() async {
    try {
      // 최신 생성일 순으로 정렬하여 각 타입/언어 조합의 최신 항목을 선택한다
      final response = await supabase
          .from('policy')
          .select()
          .order('created_at', ascending: false);
      return PolicyModel.fromJson({
        'terms_ko': response.firstWhere(
          (test) => test['type'] == 'terms' && test['language'] == 'ko',
        ),
        'terms_en': response.firstWhere(
          (test) => test['type'] == 'terms' && test['language'] == 'en',
        ),
        'privacy_ko': response.firstWhere(
          (test) => test['type'] == 'privacy' && test['language'] == 'ko',
        ),
        'privacy_en': response.firstWhere(
          (test) => test['type'] == 'privacy' && test['language'] == 'en',
        ),
      });

      // return PolicyModel.fromJson(response);
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
