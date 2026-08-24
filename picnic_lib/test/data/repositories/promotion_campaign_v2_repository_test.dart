import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';

Map<String, dynamic> _readFixture(String name) =>
    jsonDecode(
          File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  final homeJson = _readFixture('promotion_surfaces_active_v2.json');
  final badgeJson = _readFixture('promotion_surfaces_payment_badge_v2.json');
  final emptyJson = _readFixture('promotion_surfaces_empty_v2.json');

  test('decodes the V2 HOME envelope and item exactly', () {
    final model = ActivePromotionCampaignsV2Model.fromJson(homeJson);
    expect(model.items.single.multiplierTenths, 15);
    expect(model.items.single.repeatIsoDows, [1, 3, 5]);
    expect(model.items.single.homeCreative!.bannerId, 501);
    expect(model.campaignOwnedHomeBannerIds, [501]);
  });

  test(
    'decodes a PAYMENT_BADGE item with null home_creative and empty ownership',
    () {
      final model = ActivePromotionCampaignsV2Model.fromJson(badgeJson);
      expect(model.items.single.code, 'CANDY_BOOST_V2_BADGE');
      expect(model.items.single.multiplierTenths, 20);
      expect(model.items.single.homeCreative, isNull);
      expect(model.campaignOwnedHomeBannerIds, isEmpty);
      expect(model.visibleHomeItems('ko'), isEmpty);
    },
  );

  test(
    'decodes an empty dark-launch envelope with items empty and ownership retained',
    () {
      final model = ActivePromotionCampaignsV2Model.fromJson(emptyJson);
      expect(model.items, isEmpty);
      expect(model.totalCount, BigInt.zero);
      expect(model.campaignOwnedHomeBannerIds, [501]);
    },
  );

  test('localized fallback and readable creative match V1 semantics', () {
    final model = ActivePromotionCampaignsV2Model.fromJson(homeJson);
    final campaign = model.items.single;
    expect(campaign.localizedDisplayName('en'), 'Chuseok Candy Boost');
    expect(campaign.localizedDisplayName('vi'), '추석 캔디 부스트');
    expect(model.visibleHomeItems('ko'), hasLength(1));
  });

  test('empty home_creative object is normalized to null', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['home_creative'] = <String, dynamic>{};
    final model = ActivePromotionCampaignV2Model.fromJson(item);
    expect(model.homeCreative, isNull);
  });

  test('envelope, item, and nested creative reject extra keys', () {
    expect(
      () => ActivePromotionCampaignsV2Model.fromJson({
        ...homeJson,
        'extra': true,
      }),
      throwsFormatException,
    );
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    );
    expect(
      () => ActivePromotionCampaignV2Model.fromJson({...item, 'extra': true}),
      throwsFormatException,
    );
    final creative = Map<String, dynamic>.from(
      item['home_creative'] as Map,
    );
    expect(
      () => PromotionCreativeModel.fromJson({...creative, 'extra': true}),
      throwsFormatException,
    );
  });

  test('multiplier_tenths must decode as an int', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['multiplier_tenths'] = '15';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('repeat_iso_dows must decode as a list of ints', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['repeat_iso_dows'] = ['mon', 'wed'];
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('event_starts_at must decode as an ISO-8601 date', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_starts_at'] = 'not-a-date';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('event_ends_at must decode as an ISO-8601 date', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_ends_at'] = 'not-a-date';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('wireValue distinguishes HOME and PAYMENT_BADGE', () {
    expect(PromotionSurfaceV2.home.wireValue, 'HOME');
    expect(PromotionSurfaceV2.paymentBadge.wireValue, 'PAYMENT_BADGE');
  });
}
