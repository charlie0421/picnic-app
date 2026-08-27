import 'package:picnic_lib/core/analytics/ga4_currency_names.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_order.dart';

/// 무료 충전소 / 리워드 광고 GA4 이벤트의 **고정 디멘션 값**과 조립 헬퍼.
///
/// 스펙: `docs/analytics/ga4-event-taxonomy.md` §2-4 ~ §2-8.
///
/// ## 왜 AppLocalizations 에서 뽑지 않는가
/// GA4 디멘션 값은 사용자에게 보이는 텍스트가 아니라 **불변 식별자**다.
/// `AppLocalizations` 로 뽑으면 영어 기기 사용자는 `Get Cotton Candy from Ads`,
/// 한국어 기기는 `광고에서 코튼캔디 받기` 가 되어 같은 행동이 두 값으로 갈라지고,
/// 번역 문구를 고치는 순간 과거 데이터와 단절된다. 그래서 로케일과 무관한
/// 한글 상수를 여기 한 곳에 고정한다.
///
/// ## 스펙 예시값과 다른 부분 (의도적)
/// 스프레드시트는 광고 리워드의 재화를 `별사탕` 으로, 영역명을
/// `광고에서 별사탕 받기` 로 적고 있으나, 실제 제품이 광고 시청으로 지급하는
/// 재화는 **코튼캔디**(`WalletCurrency.cottonCandy`)다. 스펙 예시값을 그대로
/// 보내면 서로 다른 두 재화가 GA4 에서 한 디멘션 값으로 합쳐지므로,
/// 제품 실제값을 보낸다. (대행사 회신 항목)
class FreeChargeGa4 {
  const FreeChargeGa4._();

  // --- 영역명 (section_name) ---------------------------------------------
  // GA4 디멘션 고정값 — 로케일 무관, 변경 시 과거 데이터와 단절됨.
  /// 무료 충전소 '광고' 섹션. l10n `label_ads_get_cotton_candy` 의 ko 문구와 동일.
  static const String sectionAds = '광고에서 코튼캔디 받기';

  // --- 카테고리 (ad_category / mission_category) --------------------------
  // GA4 디멘션 고정값 — 로케일 무관, 변경 시 과거 데이터와 단절됨.
  // 서버에서 내려오는 값이 아니라 클라이언트가 l10n 문구로 조립하는 라벨이라
  // (`free_charge_station.dart` 의 `label_*_recommendation` + ' #n'),
  // 한글 기준값을 여기에 고정한다.
  static const String categoryGlobalPick = '글로벌 픽';
  static const String categoryAsiaPick = '아시아 픽';
  static const String categoryKoreaPick = '한국 픽';

  /// `글로벌 픽 #1` 처럼 카테고리 라벨에 1-base 순번을 붙인다.
  static String pick(String category, int oneBasedIndex) =>
      '$category #$oneBasedIndex';

  // --- 획득 방법 (earn_method) -------------------------------------------
  // GA4 디멘션 고정값 — 로케일 무관, 변경 시 과거 데이터와 단절됨.
  static const String earnMethodRewardedAd = '광고 리워드';

  // --- 광고 플랫폼 식별자 --------------------------------------------------
  static const String adFormatRewarded = 'rewarded';

  /// 자체 숏폼 광고(외부 SDK 없음).
  static const String platformInternalShortform = 'internal-shortform';
  static const String sourceInternalShortform = 'internal';

  static const String platformPangle = 'Pangle';
  static const String sourcePangle = 'Pangle';

  // --- 재화 이름 (virtual_currency_name) ----------------------------------
  /// [WalletCurrency] → GA4 재화 이름.
  ///
  /// **문자열을 여기서 다시 정의하지 않는다.** 재화 이름의 유일한 기준값은
  /// [Ga4CurrencyNames] 이고 이 메서드는 무료 충전소 호출부를 위한 얇은
  /// 위임일 뿐이다. 같은 문자열을 두 곳에 두면 한쪽만 고쳐졌을 때 같은 재화가
  /// GA4 에서 두 디멘션 값으로 갈라진다.
  static String currencyName(WalletCurrency currency) =>
      Ga4CurrencyNames.of(currency);

  /// 광고 시청 리워드로 지급되는 재화. `receiptFromAdReward` 가 코튼캔디만
  /// 영수증으로 인정하므로 광고 구좌의 예정 재화도 코튼캔디다.
  static String get adRewardCurrencyName => Ga4CurrencyNames.cottonCandy;

  /// 서버가 확정한 적립 건(`AdRewardReference`)의 광고 카테고리.
  ///
  /// 적립 응답에는 어느 구좌에서 시청했는지가 담기지 않으므로 reference 타입으로
  /// 역매핑한다. 현재 기본 구좌 구성(`ad_order.dart`)에서 AdMob = 글로벌 픽 #1,
  /// 내부 숏폼 = 글로벌 픽 #2, Pangle = 아시아 픽 #1 로 1:1 대응한다.
  static String adCategoryForReference(AdRewardReferenceType type) {
    if (type == AdRewardReferenceType.pangleClaim) {
      return pick(categoryAsiaPick, 1);
    }

    final platformId = switch (type) {
      AdRewardReferenceType.admobClaim => 'admob',
      AdRewardReferenceType.internalImpression => 'internal-shortform',
      AdRewardReferenceType.pangleClaim => 'pangle',
    };
    final globalOrder = defaultAdOrder
        .where((id) => id != 'pangle')
        .toList(growable: false);
    final globalIndex = globalOrder.indexOf(platformId);
    if (globalIndex < 0) {
      // A reference can only be created for a configured platform. Keep a safe
      // label if an old server reference outlives a local order configuration.
      return pick(categoryGlobalPick, 1);
    }
    return pick(categoryGlobalPick, globalIndex + 1);
  }

  /// CTA URL → `destination_type`.
  ///
  /// 호스트를 알 수 없으면 null 을 반환한다(호출부에서 T2 레이어가 `undefined`
  /// 로 대체한다). 하드코딩한 추정값을 넣지 않는다.
  static String? destinationType(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final host = Uri.tryParse(url.trim())?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;
    if (host.contains('youtube.') || host.contains('youtu.be')) {
      return 'youtube';
    }
    if (host.contains('instagram.')) return 'instagram';
    if (host.contains('tiktok.')) return 'tiktok';
    if (host.contains('twitter.') || host.contains('x.com')) return 'twitter';
    if (host.contains('apps.apple.com') || host.contains('play.google.com')) {
      return 'store';
    }
    return 'web';
  }
}

/// 한 번의 광고 시청 플로우 전체에서 함께 따라다니는 GA4 컨텍스트.
///
/// `ad_request` 를 보낸 구좌(버튼)의 정보를 `ad_impression` / `ad_click` /
/// `earn_virtual_currency` 까지 그대로 옮겨, 같은 시청 건이 이벤트마다 다른
/// 카테고리로 기록되는 것을 막는다.
class FreeChargeAdGa4Context {
  const FreeChargeAdGa4Context({
    required this.adPlatform,
    required this.adSource,
    required this.adUnitName,
    required this.adCategory,
    required this.virtualCurrencyName,
    required this.rewardAmount,
    this.sectionName = FreeChargeGa4.sectionAds,
    this.adFormat = FreeChargeGa4.adFormatRewarded,
  });

  final String adPlatform;
  final String adSource;

  /// 코드에서 실제로 얻을 수 없으면 null. 추정값을 하드코딩하지 않는다.
  final String? adUnitName;
  final String adCategory;
  final String virtualCurrencyName;
  final num rewardAmount;
  final String sectionName;
  final String adFormat;
}

/// 같은 버튼의 연타로 클릭 이벤트가 2번 나가는 것을 막는 최소 디바운스.
///
/// UX 는 건드리지 않는다 — 광고/오퍼월 호출 자체는 그대로 진행되고 **로깅만**
/// 억제한다. 광고 로딩 상태(`adLoadingStateProvider`)가 버튼을 비활성화하기까지
/// 한 프레임 남짓의 빈틈이 있어 그 사이의 연타를 걸러낸다.
class Ga4ClickDebounce {
  Ga4ClickDebounce({this.window = const Duration(seconds: 1)});

  final Duration window;
  final Map<String, DateTime> _lastLoggedAt = <String, DateTime>{};

  /// [key] 를 지금 로깅해도 되면 true. 직전 로깅으로부터 [window] 이내면 false.
  bool shouldLog(String key) {
    final now = DateTime.now();
    final last = _lastLoggedAt[key];
    if (last != null && now.difference(last) < window) return false;
    _lastLoggedAt[key] = now;
    return true;
  }
}
