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
    return ActivePromotionCampaignsV2Model.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }
}
