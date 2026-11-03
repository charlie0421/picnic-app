import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
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
) {
  final identity = ref.watch(authSessionIdentityProvider);
  final authGateway = ref.watch(walletAuthGatewayProvider);
  if (authGateway.isEnabled && identity == null) {
    return Future.value(
      ActivePromotionCampaignsV2Model(
        items: const [],
        totalCount: BigInt.zero,
        nextCursor: null,
        snapshotAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        campaignOwnedHomeBannerIds: const [],
      ),
    );
  }
  return ref.watch(promotionCampaignV2RepositoryProvider).getActive(surface);
}
