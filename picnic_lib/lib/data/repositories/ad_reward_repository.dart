import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AdRewardApi {
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  });
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference);
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  });
  Future<void> acknowledge(AdRewardReference reference);
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  );
}

class AdRewardRepository implements AdRewardApi {
  const AdRewardRepository(this.client);
  final SupabaseClient client;
  @override
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) async {
    final response = await client.functions.invoke(
      'ad-reward-claim',
      body: {
        'platform': platform,
        'placement_id': placementId,
        'client_request_id': clientRequestId,
      },
    );
    return PangleClaimModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    final value = await client.rpc(
      'get_ad_reward_status',
      params: {
        'p_reference_type': reference.type.wireValue,
        'p_reference_id': reference.id,
      },
    );
    return AdRewardStatusModel.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async {
    final value = await client.rpc(
      'list_unacknowledged_ad_rewards',
      params: {'p_cursor': cursor, 'p_limit': limit},
    );
    return AdRewardPageModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<void> acknowledge(AdRewardReference reference) async {
    await client.rpc(
      'acknowledge_ad_reward',
      params: {
        'p_reference_type': reference.type.wireValue,
        'p_reference_id': reference.id,
      },
    );
  }

  @override
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  ) => InternalShortformViewResponse.fromJson(json);
}
