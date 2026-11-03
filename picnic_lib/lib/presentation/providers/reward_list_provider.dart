import 'dart:async';

import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/reward_list_provider.g.dart';

@riverpod
class AsyncRewardList extends _$AsyncRewardList {
  @override
  Future<List<RewardModel>> build() async {
    final rewards = await _fetchRewardList();
    _retainSuccessfulResult();
    return rewards;
  }

  Future<List<RewardModel>> _fetchRewardList() async {
    final response = await supabase
        .from('reward')
        .select(
          'id, title, thumbnail, overview_images, location, size_guide, size_guide_images',
        )
        .filter('deleted_at', 'is', null)
        .order('order', ascending: true);

    return List<RewardModel>.from(response.map((e) => RewardModel.fromJson(e)));
  }

  void _retainSuccessfulResult() {
    final link = ref.keepAlive();
    Timer? expiry;
    ref.onCancel(() {
      expiry?.cancel();
      expiry = Timer(const Duration(minutes: 2), link.close);
    });
    ref.onResume(() {
      expiry?.cancel();
      expiry = null;
    });
    ref.onDispose(() => expiry?.cancel());
  }
}
