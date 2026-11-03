import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
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
) {
  final identity = ref.watch(authSessionIdentityProvider);
  final authGateway = ref.watch(walletAuthGatewayProvider);
  if (authGateway.isEnabled && identity == null) {
    return Future.value(
      ActivePromotionCampaignsModel(
        items: const [],
        totalCount: BigInt.zero,
        nextCursor: null,
        snapshotAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        campaignOwnedHomeBannerIds: const [],
      ),
    );
  }
  return ref.watch(promotionCampaignRepositoryProvider).getActive(surface);
}
