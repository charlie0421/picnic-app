import 'package:picnic_app/models/reward.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'reward_list_provider.g.dart';

@riverpod
class AsyncRewardList extends _$AsyncRewardList {
  @override
  Future<List<RewardModel>> build() async {
    return _fetchRewardList();
  }

  Future<List<RewardModel>> _fetchRewardList() async {
    final response = await Supabase.instance.client
        .from('reward')
        .select()
        .order('start_at', ascending: false);
    List<RewardModel> rewardList =
        List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
    for (var element in rewardList) {
      element.thumbnail =
          'https://cdn-dev.picnic.fan/reward/${element.id}/${element.thumbnail}';
    }
    return rewardList;
  }
}
