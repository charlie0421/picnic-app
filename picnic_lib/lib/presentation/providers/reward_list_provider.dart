import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/reward_list_provider.g.dart';

@riverpod
class AsyncRewardList extends _$AsyncRewardList {
  @override
  Future<List<RewardModel>> build() async {
    return _fetchRewardList();
  }

  Future<List<RewardModel>> _fetchRewardList() async {
    final response = await supabase
        .from('reward')
        .select(
            'id, title, thumbnail, overview_images, location, size_guide, size_guide_images')
        .filter('deleted_at', 'is', null)
        .order('order', ascending: true);

    return List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
  }
}
