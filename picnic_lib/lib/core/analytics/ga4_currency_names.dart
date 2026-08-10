import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

/// GA4 `virtual_currency_name` 의 **유일한 기준값**.
///
/// 광고·구매·투표 등 재화를 다루는 모든 이벤트가 이 매핑만 사용한다. 호출부에서
/// 재화 이름 문자열을 직접 쓰지 마라 — 같은 재화가 이벤트마다 다른 값으로 나가면
/// GA4 디멘션이 갈라진다.
///
/// ## 로케일 무관 고정값
///
/// [AppLocalizations] 에서 뽑지 않는다. 영어 기기는 `Star Candy`, 한국어 기기는
/// `스타캔디` 를 보내게 되어 같은 재화가 두 디멘션 값으로 갈라지고, 번역 문구를
/// 고치는 순간 과거 데이터와 단절된다. analytics 라벨은 사용자에게 보이는
/// 텍스트가 아니라 **불변 식별자**다.
///
/// ## 스펙과 다른 이유
///
/// 택소노미 스프레드시트는 예시값을 `별사탕` / `보너스 별사탕` 으로 적고 있으나,
/// 앱의 지갑 UI(`wallet_summary_panel.dart`)가 실제로 표시하는 이름은 지갑
/// l10n 기준 `스타캔디` / `보너스 스타캔디` / `코튼캔디` 다. `별사탕` 은 리네임
/// 이전의 옛 명칭이라 일부 l10n 문구에만 잔존한다.
///
/// 또한 **스타캔디와 코튼캔디는 별개로 공존하는 재화**다
/// ([WalletCurrency] 3종, `vote_pick` 의 `star_candy_usage` /
/// `star_candy_bonus_usage` / `cotton_candy_usage`). 스펙 예시값대로 광고
/// 리워드에 `별사탕` 을 보내면 서로 다른 두 재화가 한 디멘션 값으로 합쳐진다.
///
/// 대행사 확인 항목: `docs/analytics/ga4-event-taxonomy.md` §4
abstract final class Ga4CurrencyNames {
  /// `wallet_star_candy` (ko) 기준.
  static const String starCandy = '스타캔디';

  /// `wallet_bonus_star_candy` (ko) 기준.
  static const String bonusStarCandy = '보너스 스타캔디';

  /// `wallet_cotton_candy` (ko) 기준.
  static const String cottonCandy = '코튼캔디';

  /// [WalletCurrency] → GA4 재화 이름.
  static String of(WalletCurrency currency) => switch (currency) {
        WalletCurrency.starCandy => starCandy,
        WalletCurrency.bonusStarCandy => bonusStarCandy,
        WalletCurrency.cottonCandy => cottonCandy,
      };

  /// 한 건의 행동에 **여러 재화가 섞여 쓰인** 경우의 결합 라벨.
  ///
  /// 투표는 보너스 스타캔디를 먼저 소모하고 모자란 만큼 스타캔디를 쓰는 식으로
  /// 한 번에 2~3종이 동시에 나갈 수 있다. 이벤트를 재화별로 쪼개면 이벤트 건수가
  /// 투표 건수보다 부풀어 카운트 지표가 깨지므로, 이벤트는 1건으로 유지하고
  /// 이름만 결합한다.
  ///
  /// 순서는 [WalletCurrency] 선언 순서로 **정규화**한다. 정규화하지 않으면
  /// `스타캔디+코튼캔디` 와 `코튼캔디+스타캔디` 가 서로 다른 디멘션 값으로
  /// 갈라진다. 사용된 재화가 하나면 결합 없이 그 이름을 그대로 돌려준다.
  ///
  /// 재화별 정확한 소모량은 결합 라벨로 알 수 없으므로, 호출부는 별도의
  /// 재화별 수량 파라미터를 함께 보내야 한다.
  static String combined(Set<WalletCurrency> used) {
    final ordered = WalletCurrency.values.where(used.contains).map(of);
    return ordered.join('+');
  }
}
