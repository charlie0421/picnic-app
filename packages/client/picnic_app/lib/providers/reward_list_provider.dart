import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reward_list_provider.g.dart';

@riverpod
class AsyncRewardList extends _$AsyncRewardList {
  @override
  Future<List<RewardModel>> build() async {
    return _fetchRewardList();
  }

  Future<List<RewardModel>> _fetchRewardList() async {
    final response =
        await supabase.from('reward').select().order('id', ascending: true);

    return List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
  }
}
