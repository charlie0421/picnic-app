import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

import 'package:picnic_app/presentation/screens/portal.dart';
import '../../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../../picnic_lib/test/helpers/host_app_asset_bundle.dart';
import '../../../picnic_lib/test/helpers/mock_data.dart';
import '../../../picnic_lib/test/helpers/mock_providers.dart';
import '../../../picnic_lib/test/helpers/mock_supabase.dart';

void expectNoServiceMutation() {
  expect(
      capturedMockRequests.where((uri) =>
          uri.path.contains('/functions/v1/') &&
          RegExp(r'vot(e|ing)|purchase|receipt').hasMatch(uri.path)),
      isEmpty,
      reason: 'UI navigation must not submit a vote or verify a purchase');
}

const serviceVoteTitle = '폴더블 화면 검증 투표';
const serviceNickname = '폴더블 검증 사용자';
const serviceProducts = [
  {
    'id': 'STAR100',
    'price': 1.99,
    'star_candy': 100,
    'star_candy_bonus': 0,
    'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
  },
];

/// The real Portal, navigation notifier and pages. Only remote data and
/// purchase delivery are replaced; no store transaction can be launched.
Widget currentServiceTestApp(
    {double textScale = 1, bool deviceAssets = false}) {
  return ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      ...defaultProviderOverrides(
        overrideNavigation: false,
        userProfile:
            MockData.userProfile(nickname: serviceNickname, avatarUrl: null),
      ),
      asyncActiveFeaturedVotesProvider.overrideWith(FoldableFeaturedVotes.new),
      unreadNotificationsCountProvider.overrideWith((ref) async => 0),
      popupProvider.overrideWith((ref) async => []),
      serverProductsProvider
          .overrideWithBuild((ref, notifier) => serviceProducts),
      storeProductsProvider.overrideWithBuild((ref, notifier) => []),
      paymentBadgePromotionProvider.overrideWith((ref) async => null),
      paymentBadgePromotionPeriodProvider.overrideWith((ref) async => null),
      walletSummaryProvider.overrideWith(_ServiceWallet.new),
      globalPurchaseListenerProvider.overrideWith((ref) {
        final listener = GlobalPurchaseListener(
          container: ref.container,
          purchaseServiceFactory: (container, onUpdate) => _NoPurchaseService(),
        );
        ref.onDispose(listener.dispose);
        return listener;
      }),
    ],
    child: Builder(
        builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: AppBuilder.buildApp(
                navigatorKey: navigatorKey,
                scaffoldKey: GlobalKey<ScaffoldMessengerState>(),
                routes: const {},
                title: 'Current service foldable UI',
                theme: ThemeData(),
                home: deviceAssets
                    ? const Portal()
                    : DefaultAssetBundle(
                        bundle: hostAppAssetBundle, child: const Portal()),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ko'),
              ),
            )),
  );
}

class _ServiceWallet extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() async => WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.from(1000),
        bonus: BigInt.zero,
        cotton: BigInt.zero,
        cottonExpiringAmount: BigInt.zero,
        cottonNextExpiresAt: null,
        snapshotAt: DateTime.utc(2026, 10, 29),
      );
  @override
  Future<void> refresh() async {}
}

class _NoPurchaseService extends Fake implements PurchaseService {
  @override
  InAppPurchaseService get inAppPurchaseService => InAppPurchaseService();
  @override
  Future<PurchaseSweepReport> sweepUnfinishedPurchases({
    required PurchaseSweepTrigger trigger,
    bool Function()? shouldAbort,
  }) async =>
      PurchaseSweepReport(
          trigger: trigger, outcome: PurchaseSweepOutcome.completed);
  @override
  void dispose() {}
}

Map<String, dynamic> serviceFixtures() {
  final now = DateTime.now().toUtc();
  final item = {
    'id': 1,
    'vote_id': 1,
    'vote_total': 5000,
    'artist': {
      'id': 10,
      'name': {'ko': '검증 아티스트', 'en': 'Test Artist'},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': '검증 그룹', 'en': 'Test Group'},
        'image': null
      },
    },
    'artist_group': null,
  };
  return {
    'banner': [],
    'reward': [],
    'artist_user_bookmark': [],
    'vote': [
      {
        'id': 1,
        'title': {'ko': serviceVoteTitle, 'en': 'Foldable UI vote'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': [item],
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': [],
      }
    ],
    'vote_item': [item],
    'user_profiles': [
      {
        'id': 'test-user-id',
        'nickname': serviceNickname,
        'avatar_url': null,
        'deleted_at': null,
        'user_agreement': null,
        'is_admin': false,
        'star_candy': 1000,
        'star_candy_bonus': 0,
        'jma_candy': 0,
        'birth_date': null,
        'gender': null,
        'birth_time': null,
      }
    ],
    'media': [
      {
        'id': 1,
        'video_id': 'foldable-fixture',
        'video_url': '',
        'title': {'ko': '큰 글자에서도 읽을 수 있는 피크닉 미디어 제목'},
        'created_at': now.toIso8601String(),
        'deleted_at': null,
      }
    ],
  };
}
