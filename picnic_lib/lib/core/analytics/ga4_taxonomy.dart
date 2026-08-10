/// GA4 이벤트 택소노미 상수.
///
/// 유일한 스펙 기준은 `docs/analytics/ga4-event-taxonomy.md` 다. 이벤트 이름과
/// 파라미터 이름 문자열 리터럴이 호출부에 흩어지면 오타 하나가 통째로 유실되는
/// 이벤트가 되므로, 모든 이름은 여기에서만 정의하고 호출부는 상수만 참조한다.
library;

/// 이벤트 이름 (스펙 §2).
class Ga4Event {
  const Ga4Event._();

  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String clickAttendance = 'click_attendance';
  static const String clickMission = 'click_mission';
  static const String adRequest = 'ad_request';

  /// 주의: `ad_impression` 은 Firebase↔AdMob 연동 시 **SDK 가 자동 수집하는
  /// 이벤트 이름과 동일**하다. 본 택소노미는 스펙대로 커스텀 logEvent 를
  /// 수행하므로, AdMob 자동수집이 켜져 있는 빌드에서는 같은 노출이 두 번
  /// 집계될 수 있다. 대행사와 합의된 사항(스펙 §2-6 주석)이며, 리포트에서
  /// 중복이 확인되면 자동수집을 끄거나 커스텀 로깅을 제거하는 쪽으로
  /// 한쪽을 정리해야 한다.
  static const String adImpression = 'ad_impression';

  static const String earnVirtualCurrency = 'earn_virtual_currency';
  static const String adClick = 'ad_click';
  static const String purchase = 'purchase';
  static const String vote = 'vote';

  /// 스펙에 정의된 전체 이벤트 목록 (테스트/검증용).
  static const List<String> all = <String>[
    login,
    signUp,
    clickAttendance,
    clickMission,
    adRequest,
    adImpression,
    earnVirtualCurrency,
    adClick,
    purchase,
    vote,
  ];
}

/// 이벤트/아이템 수준 파라미터 이름 (스펙 §3 공통 파라미터 사전).
class Ga4Param {
  const Ga4Param._();

  // Event 수준
  static const String method = 'method';
  static const String selectedLanguage = 'selected_language';
  static const String virtualCurrencyName = 'virtual_currency_name';
  static const String rewardAmount = 'reward_amount';
  static const String missionCategory = 'mission_category';
  static const String sectionName = 'section_name';
  static const String adCategory = 'ad_category';
  static const String adPlatform = 'ad_platform';
  static const String adSource = 'ad_source';
  static const String adFormat = 'ad_format';
  static const String adUnitName = 'ad_unit_name';
  static const String earnMethod = 'earn_method';
  static const String destinationType = 'destination_type';
  static const String transactionId = 'transaction_id';
  static const String currency = 'currency';
  static const String value = 'value';
  static const String voteId = 'vote_id';
  static const String voteName = 'vote_name';
  static const String voteReward = 'vote_reward';
  static const String voteStartDate = 'vote_start_date';
  static const String voteEndDate = 'vote_end_date';
  static const String voteArtistName = 'vote_artist_name';
  static const String voteArtistGroup = 'vote_artist_group';

  /// 스펙 외 **가산적** 확장 (vote 전용, 재화별 소모량).
  ///
  /// 스펙은 `virtual_currency_name` + `reward_amount` 스칼라 1쌍만 정의하지만,
  /// 투표는 보너스 스타캔디를 먼저 쓰고 모자란 만큼 스타캔디를 쓰는 식으로 한
  /// 번에 2~3종을 동시에 소모한다. 결합 라벨
  /// ([Ga4CurrencyNames.combined])만으로는 "스타캔디+보너스 스타캔디, 총 100"
  /// 에서 어느 재화가 얼마인지 복원할 수 없어 재화별 소모량 집계가 불가능하다.
  ///
  /// 이벤트를 재화별로 쪼개면 vote 이벤트 건수가 투표 건수보다 부풀어 투표
  /// 카운트 지표가 깨지므로, 이벤트는 1건으로 두고 수량만 파라미터로 분해한다.
  /// 스펙 값을 덮어쓰지 않는 순수 추가라 기존 리포트는 영향받지 않는다.
  ///
  /// 이름은 DB(`vote_pick`)의 컬럼명과 일치시켰다 — BigQuery ↔ Supabase 조인
  /// 시 컬럼을 매핑할 필요가 없다.
  static const String starCandyUsage = 'star_candy_usage';
  static const String starCandyBonusUsage = 'star_candy_bonus_usage';
  static const String cottonCandyUsage = 'cotton_candy_usage';

  // Item 수준 (purchase 의 items 배열)
  static const String itemId = 'item_id';
  static const String itemName = 'item_name';
  static const String baseAmount = 'base_amount';
  static const String bonusAmount = 'bonus_amount';
}

/// 사용자 속성 이름 (스펙 §1).
///
/// 스프레드시트 내부에 이름 불일치가 있다: "파라미터 리스트" 시트는 `language`,
/// "공통 파라미터" 시트는 `selected_language`. **사용자 속성은 `language` 로
/// 통일**하고, 이벤트 수준 파라미터는 `selected_language` 를 쓴다.
/// 이 불일치는 docs/analytics/ga4-event-taxonomy.md 의 '대행사 확인 필요'
/// 섹션에 기록되어 있다.
class Ga4UserProperty {
  const Ga4UserProperty._();

  static const String isLogin = 'is_login';
  static const String language = 'language';

  // 기존 리포트가 의존할 수 있어 유지하는 레거시 속성 (스펙 외).
  static const String userRole = 'user_role';
  static const String locale = 'locale';
  static const String isTester = 'is_tester';
  static const String appEnv = 'app_env';
}

/// 스펙에 정의된 고정 값들.
class Ga4Value {
  const Ga4Value._();

  /// 정보가 없는 경우의 대체값 (스펙 §2 서두).
  static const String undefined = 'undefined';

  static const String loggedIn = 'Y';
  static const String loggedOut = 'N';
}

/// 로그인/회원가입 `method` 파라미터 허용값 (스펙 §2-1, §2-2).
class Ga4LoginMethod {
  const Ga4LoginMethod._();

  static const String apple = 'apple';
  static const String google = 'google';
  static const String kakao = 'kakao';

  static const List<String> all = <String>[apple, google, kakao];
}
