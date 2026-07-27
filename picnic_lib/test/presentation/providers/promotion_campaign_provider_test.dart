import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_repository.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Repository extends PromotionCampaignRepository {
  _Repository(this.value) : super(SupabaseClient('http://localhost', 'key'));
  final ActivePromotionCampaignsModel value;
  PromotionSurface? requested;
  @override
  Future<ActivePromotionCampaignsModel> getActive(
    PromotionSurface surface,
  ) async {
    requested = surface;
    return value;
  }
}

void main() {
  test(
    'surface family forwards exact surface and returns same envelope',
    () async {
      final value = ActivePromotionCampaignsModel.fromJson(
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final repository = _Repository(value);
      final container = ProviderContainer(
        overrides: [
          promotionCampaignRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final actual = await container.read(
        activePromotionCampaignProvider(PromotionSurface.home).future,
      );
      expect(identical(actual, value), isTrue);
      expect(repository.requested, PromotionSurface.home);
    },
  );
}
