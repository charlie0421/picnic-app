import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final creative = Map<String, dynamic>.from(item['home_creative'] as Map);
    expect(
      () => PromotionCreativeModel.fromJson({...creative, 'extra': true}),
      throwsFormatException,
    );
  });

  test(
    'nested creative extra key is rejected recursively through the V2 envelope',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      );
      final creative = Map<String, dynamic>.from(
        item['home_creative'] as Map,
      );
      final envelope = {
        ...homeJson,
        'items': [
          {...item, 'home_creative': {...creative, 'extra': true}},
        ],
      };
      expect(
        () => ActivePromotionCampaignsV2Model.fromJson(envelope),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test('multiplier_tenths must decode as an int', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['multiplier_tenths'] = '15';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test(
    'multiplier_tenths must decode as an int without truncating a fractional value',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      )..['multiplier_tenths'] = 15.9;
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test('repeat_iso_dows must decode as a list of ints', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['repeat_iso_dows'] = ['mon', 'wed'];
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test(
    'repeat_iso_dows must decode as a list of ints without truncating fractional values',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      )..['repeat_iso_dows'] = [1.9, 3];
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test(
    'campaign_owned_home_banner_ids must decode as a list of ints without truncating fractional values',
    () {
      final envelope = {
        ...homeJson,
        'campaign_owned_home_banner_ids': [501.9],
      };
      expect(
        () => ActivePromotionCampaignsV2Model.fromJson(envelope),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test(
    'nested home_creative banner_id must decode as an int without truncating a fractional value',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      );
      final creative = Map<String, dynamic>.from(item['home_creative'] as Map)
        ..['banner_id'] = 501.9;
      item['home_creative'] = creative;
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsFormatException,
      );
    },
  );

  test(
    'nested home_creative duration must decode as an int without truncating a fractional value',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      );
      final creative = Map<String, dynamic>.from(item['home_creative'] as Map)
        ..['duration'] = 4000.5;
      item['home_creative'] = creative;
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsFormatException,
      );
    },
  );

  test('event_starts_at must decode as an ISO-8601 date', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_starts_at'] = 'not-a-date';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test(
    'event_starts_at must reject a timestamp without an explicit UTC offset',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      )..['event_starts_at'] = '2026-09-07T00:00:00';
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test('event_starts_at must reject a calendar date that does not exist', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_starts_at'] = '2026-02-31T00:00:00Z';
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

  test(
    'event_ends_at must reject a timestamp without an explicit UTC offset',
    () {
      final item = Map<String, dynamic>.from(
        (homeJson['items'] as List).single as Map,
      )..['event_ends_at'] = '2026-09-14T00:00:00';
      expect(
        () => ActivePromotionCampaignV2Model.fromJson(item),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test('event_ends_at must reject a calendar date that does not exist', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_ends_at'] = '2026-02-31T00:00:00Z';
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test(
    'snapshot_at must reject a timestamp without an explicit UTC offset',
    () {
      final envelope = {...homeJson, 'snapshot_at': '2026-09-07T00:10:00'};
      expect(
        () => ActivePromotionCampaignsV2Model.fromJson(envelope),
        throwsA(isA<CheckedFromJsonException>()),
      );
    },
  );

  test('snapshot_at must reject a calendar date that does not exist', () {
    final envelope = {...homeJson, 'snapshot_at': '2026-02-31T00:10:00Z'};
    expect(
      () => ActivePromotionCampaignsV2Model.fromJson(envelope),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('multiplier_tenths below the backend bound of 11 is rejected', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['multiplier_tenths'] = 10;
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('multiplier_tenths above the backend bound of 30 is rejected', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['multiplier_tenths'] = 31;
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('repeat_iso_dows must not be empty', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['repeat_iso_dows'] = <int>[];
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('repeat_iso_dows rejects out-of-range and duplicate values', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['repeat_iso_dows'] = [7, 7, 0, 8];
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('repeat_iso_dows must be sorted ascending', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['repeat_iso_dows'] = [3, 1];
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('event_starts_at must be before event_ends_at', () {
    final item = Map<String, dynamic>.from(
      (homeJson['items'] as List).single as Map,
    )..['event_starts_at'] = '2026-09-21T00:00:00+09:00';
    // event_ends_at in the fixture is 2026-09-14T00:00:00+09:00, now earlier
    // than the mutated event_starts_at above.
    expect(
      () => ActivePromotionCampaignV2Model.fromJson(item),
      throwsFormatException,
    );
  });

  test('total_count must be a decimal string, not a JSON number', () {
    final envelope = {...homeJson, 'total_count': 1};
    expect(
      () => ActivePromotionCampaignsV2Model.fromJson(envelope),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('total_count must not be negative', () {
    final envelope = {...homeJson, 'total_count': '-1'};
    expect(
      () => ActivePromotionCampaignsV2Model.fromJson(envelope),
      throwsFormatException,
    );
  });

  test('total_count accepts arbitrarily large decimal strings', () {
    final envelope = {
      ...homeJson,
      'total_count': '999999999999999999999999',
    };
    final model = ActivePromotionCampaignsV2Model.fromJson(envelope);
    expect(model.totalCount, BigInt.parse('999999999999999999999999'));
  });

  test('wireValue distinguishes HOME and PAYMENT_BADGE', () {
    expect(PromotionSurfaceV2.home.wireValue, 'HOME');
    expect(PromotionSurfaceV2.paymentBadge.wireValue, 'PAYMENT_BADGE');
  });

  test(
    'requests get_active_promotion_campaigns_v2 with HOME surface',
    () async {
      late Uri requestedUri;
      late String requestedMethod;
      late Map<String, dynamic> requestedBody;
      final fixture = File(
        'test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json',
      ).readAsStringSync();
      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          requestedMethod = request.method;
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
      final result = await PromotionCampaignV2Repository(
        client,
      ).getActive(PromotionSurfaceV2.home);
      expect(
        requestedUri.path,
        '/rest/v1/rpc/get_active_promotion_campaigns_v2',
      );
      expect(requestedMethod, 'POST');
      expect(requestedBody, {'p_surface': 'HOME'});
      expect(result.items.single.code, 'CANDY_BOOST_V2');
    },
  );

  test(
    'requests get_active_promotion_campaigns_v2 with PAYMENT_BADGE surface',
    () async {
      late Uri requestedUri;
      late String requestedMethod;
      late Map<String, dynamic> requestedBody;
      final fixture = File(
        'test/fixtures/wallet_contracts/promotion_surfaces_payment_badge_v2.json',
      ).readAsStringSync();
      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          requestedMethod = request.method;
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
      final result = await PromotionCampaignV2Repository(
        client,
      ).getActive(PromotionSurfaceV2.paymentBadge);
      expect(
        requestedUri.path,
        '/rest/v1/rpc/get_active_promotion_campaigns_v2',
      );
      expect(requestedMethod, 'POST');
      expect(requestedBody, {'p_surface': 'PAYMENT_BADGE'});
      expect(result.items.single.code, 'CANDY_BOOST_V2_BADGE');
      expect(result.items.single.homeCreative, isNull);
    },
  );

  test(
    'PAYMENT_BADGE response carrying HOME creative or ownership is rejected',
    () async {
      // Simulates a swapped/cross-surface response: the server (or a proxy
      // bug) returns HOME-shaped data while PAYMENT_BADGE was requested.
      final fixture = File(
        'test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json',
      ).readAsStringSync();
      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        httpClient: MockClient(
          (request) async => http.Response(
            fixture,
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await expectLater(
        PromotionCampaignV2Repository(
          client,
        ).getActive(PromotionSurfaceV2.paymentBadge),
        throwsFormatException,
      );
    },
  );
}
