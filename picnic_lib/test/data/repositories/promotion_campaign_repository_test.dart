import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('uses server clock RPC without an at parameter', () async {
    late Uri requestedUri;
    late Map<String, dynamic> requestedBody;
    final fixture = File(
      'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
    ).readAsStringSync();
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          fixture,
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await PromotionCampaignRepository(client).getActive(PromotionSurface.home);
    expect(requestedUri.path, contains('/rpc/get_active_promotion_campaigns'));
    expect(requestedBody, {'surface': 'HOME'});
    expect(requestedBody, isNot(contains('at')));
  });

  test('active fixture uses localized fallback and readable creative', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final result = ActivePromotionCampaignsModel.fromJson(json);
    final campaign = result.items.single;
    expect(campaign.localizedDisplayName('en'), 'Candy Boost Day');
    expect(campaign.localizedDisplayName('vi'), '캔디 부스트 데이');
    expect(result.visibleHomeItems('ko'), hasLength(1));
    expect(result.campaignOwnedHomeBannerIds, [101]);
  });

  test('malformed creative is hidden but ownership remains', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final item = Map<String, dynamic>.from(
      (json['items'] as List).single as Map,
    );
    item['home_creative'] = {
      ...Map<String, dynamic>.from(item['home_creative'] as Map),
      'title': <String, dynamic>{},
    };
    final result = ActivePromotionCampaignsModel.fromJson({
      ...json,
      'items': [item],
    });
    expect(result.visibleHomeItems('ko'), isEmpty);
    expect(result.campaignOwnedHomeBannerIds, contains(101));
  });

  test('empty creative object is normalized to hidden', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final item = Map<String, dynamic>.from(
      (json['items'] as List).single as Map,
    )..['home_creative'] = <String, dynamic>{};
    final result = ActivePromotionCampaignsModel.fromJson({
      ...json,
      'items': [item],
    });
    expect(result.visibleHomeItems('ko'), isEmpty);
  });

  test('envelope, item, and non-empty creative reject extra keys', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(
      () => ActivePromotionCampaignsModel.fromJson({...json, 'extra': true}),
      throwsFormatException,
    );
    final item = Map<String, dynamic>.from(
      (json['items'] as List).single as Map,
    );
    expect(
      () => ActivePromotionCampaignModel.fromJson({...item, 'extra': true}),
      throwsFormatException,
    );
    final creative = Map<String, dynamic>.from(item['home_creative'] as Map);
    expect(
      () => PromotionCreativeModel.fromJson({...creative, 'extra': true}),
      throwsFormatException,
    );
  });
}
