import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionCampaignRepository {
  const PromotionCampaignRepository(this.client);
  static const _requestTimeout = Duration(seconds: 5);

  final SupabaseClient client;

  Future<ActivePromotionCampaignsModel> getActive(
    PromotionSurface surface,
  ) async {
    // Future.timeout does not cancel the in-flight RPC. The transport client
    // still owns its response deadline (RetryHttpClient defaults to 30s).
    final value = await client.rpc(
      'get_active_promotion_campaigns',
      params: {'surface': surface.wireValue},
    ).timeout(_requestTimeout);
    return ActivePromotionCampaignsModel.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }
}
