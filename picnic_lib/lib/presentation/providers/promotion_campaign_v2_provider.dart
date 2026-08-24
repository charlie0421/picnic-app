import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/promotion_campaign_v2_provider.g.dart';

@Riverpod(keepAlive: true)
PromotionCampaignV2Repository promotionCampaignV2Repository(Ref ref) =>
    PromotionCampaignV2Repository(supabase);

@riverpod
Future<ActivePromotionCampaignsV2Model> activePromotionCampaignV2(
  Ref ref,
  PromotionSurfaceV2 surface,
) => ref.watch(promotionCampaignV2RepositoryProvider).getActive(surface);
