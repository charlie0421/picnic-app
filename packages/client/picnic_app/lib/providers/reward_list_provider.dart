import 'package:picnic_app/constants.dart';
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

    logger.d(response);

    List<RewardModel> rewardList =
        List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
    for (var i = 0; i < rewardList.length; i++) {
      rewardList[i] = rewardList[i].copyWith(
          thumbnail:
              'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/${rewardList[i].thumbnail}');

      rewardList[i] = rewardList[i].copyWith(
          overview_images: rewardList[i]
              .overview_images
              ?.map((e) =>
                  'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/$e')
              .toList(),
          location_images: rewardList[i]
              .location_images
              ?.map((e) =>
                  'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/$e')
              .toList(),
          size_guide_images: rewardList[i]
              .size_guide_images
              ?.map((e) =>
                  'https://cdn-dev.picnic.fan/reward/${rewardList[i].id}/$e')
              .toList());

      logger.i('rewardList[$i]: ${rewardList[i]}');
    }

    return rewardList;
  }
}
