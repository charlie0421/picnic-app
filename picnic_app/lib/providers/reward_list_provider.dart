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
        .order('id', ascending: true);

    List<RewardModel> rewardList =
    List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
    for (var i = 0; i < rewardList.length; i++) {
      rewardList[i] = rewardList[i].copyWith(
          thumbnail:
          'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/${rewardList[i]
              .thumbnail}');

      rewardList[i] = rewardList[i].copyWith(
          size_guide_images: rewardList[i]
              .size_guide_images
              ?.map((e) =>
          'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/$e')
              .toList());
    }

    return rewardList;
  }
}
