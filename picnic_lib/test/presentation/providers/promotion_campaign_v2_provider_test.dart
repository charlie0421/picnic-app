import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _readFixture(String name) =>
    jsonDecode(
          File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
        )
        as Map<String, dynamic>;

class _Repository extends PromotionCampaignV2Repository {
  _Repository(this.values) : super(SupabaseClient('http://localhost', 'key'));
  final Map<PromotionSurfaceV2, ActivePromotionCampaignsV2Model> values;
  final List<PromotionSurfaceV2> requests = [];

  @override
  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) async {
    requests.add(surface);
    return values[surface]!;
  }
}

void main() {
  test(
    'HOME and PAYMENT_BADGE are independent cache entries forwarding the exact surface',
    () async {
      final homeValue = ActivePromotionCampaignsV2Model.fromJson(
        _readFixture('promotion_surfaces_active_v2.json'),
      );
      final badgeValue = ActivePromotionCampaignsV2Model.fromJson(
        _readFixture('promotion_surfaces_payment_badge_v2.json'),
      );
      final repository = _Repository({
        PromotionSurfaceV2.home: homeValue,
        PromotionSurfaceV2.paymentBadge: badgeValue,
      });
      final container = ProviderContainer(
        overrides: [
          promotionCampaignV2RepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep both family instances alive via explicit listeners instead of
      // relying on container.exists(), which races autoDispose timing.
      final homeSub = container.listen(
        activePromotionCampaignV2Provider(PromotionSurfaceV2.home),
        (_, _) {},
      );
      addTearDown(homeSub.close);
      final badgeSub = container.listen(
        activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
        (_, _) {},
      );
      addTearDown(badgeSub.close);

      final home = await container.read(
        activePromotionCampaignV2Provider(PromotionSurfaceV2.home).future,
      );
      final badge = await container.read(
        activePromotionCampaignV2Provider(
          PromotionSurfaceV2.paymentBadge,
        ).future,
      );

      expect(identical(home, homeValue), isTrue);
      expect(identical(badge, badgeValue), isTrue);
      expect(home, isNot(equals(badge)));
      // A single mutable "last request" field cannot prove both surfaces
      // were forwarded; record the exact call sequence instead.
      expect(repository.requests, [
        PromotionSurfaceV2.home,
        PromotionSurfaceV2.paymentBadge,
      ]);

      // Re-reading synchronously must return the cached instance without
      // triggering another repository call, proving both family entries
      // stayed alive independently under their own listeners.
      expect(
        container.read(activePromotionCampaignV2Provider(PromotionSurfaceV2.home)).value,
        homeValue,
      );
      expect(
        container
            .read(
              activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
            )
            .value,
        badgeValue,
      );
      expect(repository.requests, [
        PromotionSurfaceV2.home,
        PromotionSurfaceV2.paymentBadge,
      ]);
    },
  );
}
