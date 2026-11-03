import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';
import 'package:picnic_lib/supabase_options.dart';

const extendedLongCopy =
    'Very long translated information about voting and account settings';

class LayoutWallet extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() async => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.from(123456789),
    bonus: BigInt.from(987654321),
    cotton: BigInt.from(123456789),
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 10, 29),
  );
}

class LayoutHistoryRepository extends WalletRepository {
  LayoutHistoryRepository() : super(testSupabaseClient!);
  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async => CurrencyHistoryPageModel(
    items: [
      CurrencyHistoryItemModel(
        id: 'layout',
        currency: currency,
        eventType: 'TEST',
        origin: 'ui_fixture',
        delta: BigInt.from(-123456789),
        balanceEffect: BigInt.from(-123456789),
        operationId: 'layout',
        createdAt: DateTime.utc(2026, 10, 29),
      ),
    ],
    totalCount: BigInt.one,
    nextCursor: null,
    snapshotAt: DateTime.utc(2026, 10, 29),
  );
}

class LayoutChargeContent extends StatefulWidget {
  const LayoutChargeContent({super.key, this.title = extendedLongCopy});
  final String title;
  @override
  State<LayoutChargeContent> createState() => _LayoutChargeContentState();
}

class _LayoutChargeContentState extends State<LayoutChargeContent>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void denyExternalAction() =>
      throw StateError('This UI test must not launch an ad or offerwall');
  @override
  Widget build(BuildContext context) => FreeChargeContent(
    buttonScaleAnimation: const AlwaysStoppedAnimation(1),
    rotationController: controller,
    onPolicyTap: denyExternalAction,
    onPincruxOfferwallPressed: denyExternalAction,
    missionItemBuilder: (_) => [
      ChargeStationItem(
        id: 'mission',
        title: widget.title,
        isMission: true,
        platformType: AdPlatformType.tapjoy,
        onPressed: denyExternalAction,
        bonusText: '123456789',
      ),
    ],
    adItemBuilder: (_) => [
      ChargeStationItem(
        id: 'ad',
        title: widget.title,
        isMission: false,
        platformType: AdPlatformType.admob,
        onPressed: denyExternalAction,
        bonusText: '123456789',
      ),
    ],
  );
}

Map<String, dynamic> extendedScreenFixtures() => {
  'user_notifications': [
    {
      'id': 1,
      'user_id': 'test-user-id',
      'title': {
        'ko': extendedLongCopy,
        'en': extendedLongCopy,
        'es': extendedLongCopy,
      },
      'body': {
        'ko': extendedLongCopy,
        'en': extendedLongCopy,
        'es': extendedLongCopy,
      },
      'data': {},
      'type': 'default',
      'is_read': false,
      'created_at': '2026-10-29T00:00:00Z',
    },
  ],
  'broadcast_notifications': [],
  'vote_pick': [
    {
      'id': 1,
      'amount': 123456789,
      'star_candy_usage': 123456789,
      'star_candy_bonus_usage': 123456789,
      'cotton_candy_usage': 123456789,
      'created_at': '2026-10-29T00:00:00Z',
      'updated_at': '2026-10-29T00:00:00Z',
      'vote': {
        'id': 1,
        'title': {
          'ko': extendedLongCopy,
          'en': extendedLongCopy,
          'es': extendedLongCopy,
        },
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'created_at': '2026-10-29T00:00:00Z',
        'visible_at': null,
        'is_partnership': false,
        'partner': null,
      },
      'vote_item': {
        'id': 1,
        'vote_total': 100,
        'star_candy_total': 100,
        'star_candy_bonus_total': 0,
        'vote_id': 1,
        'artist': {
          'id': 1,
          'name': {
            'ko': extendedLongCopy,
            'en': extendedLongCopy,
            'es': extendedLongCopy,
          },
        },
        'artist_group': null,
      },
    },
  ],
};

class LayoutMemoryStorage implements LocalStorage {
  final values = <String, String>{};
  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      values[key] ?? defaultValue;
  @override
  Future<void> saveData(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> removeData(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    values.clear();
  }
}
