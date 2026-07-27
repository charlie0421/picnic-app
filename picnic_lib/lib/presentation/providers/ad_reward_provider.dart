import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/ad_reward_provider.g.dart';

@Riverpod(keepAlive: true)
AdRewardApi adRewardRepository(Ref ref) => AdRewardRepository(supabase);

@Riverpod(keepAlive: true)
PendingAdRewardStore pendingAdRewardStore(Ref ref) =>
    PendingAdRewardStore(LocalStorage());
