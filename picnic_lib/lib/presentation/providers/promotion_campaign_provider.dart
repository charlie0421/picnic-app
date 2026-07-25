import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/promotion_campaign_provider.g.dart';

@Riverpod(keepAlive: true)
PromotionCampaignRepository promotionCampaignRepository(Ref ref) =>
    PromotionCampaignRepository(supabase);

@riverpod
Future<ActivePromotionCampaignsModel> activePromotionCampaign(
  Ref ref,
  PromotionSurface surface,
) => ref.watch(promotionCampaignRepositoryProvider).getActive(surface);
