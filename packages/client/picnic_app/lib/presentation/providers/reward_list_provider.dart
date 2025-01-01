import 'package:picnic_app/data/models/reward.dart';
import 'package:picnic_app/supabase_options.dart';
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
        .order('order', ascending: true);

    return List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
  }
}
