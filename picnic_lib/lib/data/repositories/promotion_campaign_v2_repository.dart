import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionCampaignV2Repository {
  const PromotionCampaignV2Repository(this.client);
  final SupabaseClient client;

  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) async {
    final value = await client.rpc(
      'get_active_promotion_campaigns_v2',
      params: {'p_surface': surface.wireValue},
    );
    final decoded = ActivePromotionCampaignsV2Model.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
    _requireSurfaceConsistency(decoded, surface);
    return decoded;
  }
}

// The backend nulls creative and omits ownership outside HOME (see
// get_active_promotion_campaigns_v2 in the read RPC migration). A swapped
// response for PAYMENT_BADGE must fail loudly instead of being cached as
// valid. HOME is intentionally left unconstrained here: active-but-unreadable
// HOME creative must remain authoritative, not be rejected.
void _requireSurfaceConsistency(
  ActivePromotionCampaignsV2Model envelope,
  PromotionSurfaceV2 surface,
) {
  if (surface != PromotionSurfaceV2.paymentBadge) return;
  if (envelope.campaignOwnedHomeBannerIds.isNotEmpty) {
    throw FormatException(
      'PAYMENT_BADGE response must not carry HOME ownership, got '
      '${envelope.campaignOwnedHomeBannerIds}',
    );
  }
  for (final item in envelope.items) {
    if (item.homeCreative != null) {
      throw FormatException(
        'PAYMENT_BADGE items must not carry home_creative, got campaign '
        '${item.campaignId}',
      );
    }
  }
}
