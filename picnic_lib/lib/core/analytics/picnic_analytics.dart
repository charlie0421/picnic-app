import 'package:flutter/foundation.dart';

import 'package:picnic_lib/core/analytics/ga4_currency_names.dart';
import 'package:picnic_lib/core/analytics/ga4_language.dart';
import 'package:picnic_lib/core/analytics/ga4_parameters.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// GA4 이벤트 택소노미(`docs/analytics/ga4-event-taxonomy.md`) 구현 레이어.
///
/// 설계 원칙
/// 1. 이벤트 이름·파라미터 이름 문자열은 [Ga4Event] / [Ga4Param] 에만 존재한다.
/// 2. 파라미터 **값**은 스프레드시트 예시값을 그대로 쓴다. 한글 값
///    ('별사탕', '광고에서 별사탕 받기', '글로벌 픽 #1' 등)을 영문 슬러그로
///    정규화하지 않는다 — 대행사 리포트가 스프레드시트 값 기준으로 잡혀 있고,
///    정규화하면 스펙과 실제 수집값이 갈라져 검수가 불가능해진다.
/// 3. 어떤 경우에도 앱을 죽이지 않는다. 단, 예외를 완전히 삼키지 않고 반드시
///    logger 로 남긴다.
/// 4. **모든 발송 메서드는 실제 전송 성공 여부를 `bool` 로 돌려준다.** 앱을
///    죽이지 않는 것과 실패를 성공으로 보고하는 것은 다르다. 중복 방어 마커를
///    남길지 결정하는 호출부는 이 값 하나만 본다 ([Ga4Sink] 전송 성공 계약).
class PicnicAnalytics {
  PicnicAnalytics({Ga4Sink sink = const FirebaseGa4Sink()}) : _sink = sink;

  final Ga4Sink _sink;

  static PicnicAnalytics _instance = PicnicAnalytics();

  static PicnicAnalytics get instance => _instance;

  /// 테스트에서 싱크를 갈아끼우기 위한 훅. 프로덕션 코드에서 호출하지 않는다.
  @visibleForTesting
  static void overrideInstance(PicnicAnalytics analytics) {
    _instance = analytics;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = PicnicAnalytics();
  }

  @visibleForTesting
  Ga4Sink get sink => _sink;

  // ---------------------------------------------------------------------------
  // 사용자 속성 (스펙 §1)
  // ---------------------------------------------------------------------------

  /// 로그인 사용자의 GA4 user_id 를 설정한다.
  ///
  /// **해시하지 않고 Supabase `auth.users.id` (UUID) 를 그대로 넣는다.**
  /// 스프레드시트 §1 은 "해시값"이라고 적고 있으나 현행 유지가 옳다:
  ///   - UUID 는 랜덤 식별자라 그 자체로는 개인을 식별하지 못한다(PII 아님).
  ///     이메일·전화번호·이름 등 직접 식별 정보는 애초에 넣지 않는다.
  ///   - 해시하면 BigQuery(GA4 export)의 `user_id` 와 Supabase `user_profiles.id`
  ///     조인이 끊겨 퍼널·리텐션 분석이 불가능해진다.
  ///   - 이미 수집 중인 GA4 user_id 히스토리와 단절되어 기존 코호트가 갈라진다.
  /// 이 근거는 docs/analytics/ga4-event-taxonomy.md 에도 기록되어 있다.
  Future<bool> setUserProperties({
    required String? userId,
    required bool isLogin,
    required String? language,
    String? userRole,
    String? locale,
    bool? isTester,
    String? appEnv,
  }) {
    return _guard('setUserProperties', () async {
      var ok = await _sink.setUserId(userId);

      ok &= await _sink.setUserProperty(
        Ga4UserProperty.isLogin,
        isLogin ? Ga4Value.loggedIn : Ga4Value.loggedOut,
      );

      // 앱 코드(`ja`) → 스펙 표기(`jp`). 정규화는 여기 한 곳에서만 한다.
      final normalizedLanguage = Ga4Language.normalize(language);
      if (normalizedLanguage != null) {
        ok &= await _sink.setUserProperty(
          Ga4UserProperty.language,
          Ga4Parameters.stringValue(normalizedLanguage),
        );
      }

      // 스펙 외 레거시 속성. 기존 리포트가 의존할 수 있어 제거하지 않는다.
      if (userRole != null && userRole.isNotEmpty) {
        ok &= await _sink.setUserProperty(Ga4UserProperty.userRole, userRole);
      }
      // `locale` 은 스펙에 없는 레거시 속성이라 정규화하지 않는다. 앱이 쓰는
      // 원본 코드(`ja`)를 그대로 유지해야 기존 리포트가 끊기지 않는다.
      if (locale != null && locale.isNotEmpty) {
        ok &= await _sink.setUserProperty(Ga4UserProperty.locale, locale);
      }
      if (isTester != null) {
        ok &= await _sink.setUserProperty(
          Ga4UserProperty.isTester,
          isTester ? 'true' : 'false',
        );
      }
      if (appEnv != null && appEnv.isNotEmpty) {
        ok &= await _sink.setUserProperty(Ga4UserProperty.appEnv, appEnv);
      }
      return ok;
    });
  }

  /// 로그아웃 시 사용자 속성을 정리한다.
  ///
  /// `is_login` 은 제거하지 않고 `'N'` 으로 **갱신**한다. null 로 지우면
  /// 비로그인 세션이 "값 없음"이 되어 로그인/비로그인 세그먼트가 갈라지지 않는다.
  /// `language` 도 로그아웃과 무관하게 유효하므로 유지한다.
  Future<bool> clearUserProperties() {
    return _guard('clearUserProperties', () async {
      var ok = await _sink.setUserId(null);
      ok &= await _sink.setUserProperty(
        Ga4UserProperty.isLogin,
        Ga4Value.loggedOut,
      );
      ok &= await _sink.setUserProperty(Ga4UserProperty.userRole, null);
      ok &= await _sink.setUserProperty(Ga4UserProperty.locale, null);
      ok &= await _sink.setUserProperty(Ga4UserProperty.isTester, null);
      ok &= await _sink.setUserProperty(Ga4UserProperty.appEnv, null);
      return ok;
    });
  }

  // ---------------------------------------------------------------------------
  // 1. login (스펙 §2-1)
  // ---------------------------------------------------------------------------

  /// 로그인 완료 시점(통신 시점)에 호출한다.
  ///
  /// [method] 는 `apple` / `google` / `kakao`.
  /// [selectedLanguage] 는 로그인 직전 선택된 언어 (앱 코드 그대로 넘기면 된다 —
  /// [Ga4Language] 가 `ja` 를 스펙 표기 `jp` 로 바꿔 보낸다).
  Future<bool> logLogin({
    required String? method,
    required String? selectedLanguage,
  }) {
    return _log(
      Ga4Event.login,
      strings: <String, String?>{
        Ga4Param.method: method,
        Ga4Param.selectedLanguage: Ga4Language.normalize(selectedLanguage),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. sign_up (스펙 §2-2)
  // ---------------------------------------------------------------------------

  /// 회원가입 완료 시점(통신 시점)에 호출한다.
  ///
  /// [selectedLanguage] 정규화 규칙은 [logLogin] 과 동일하다.
  Future<bool> logSignUp({
    required String? method,
    required String? selectedLanguage,
  }) {
    return _log(
      Ga4Event.signUp,
      strings: <String, String?>{
        Ga4Param.method: method,
        Ga4Param.selectedLanguage: Ga4Language.normalize(selectedLanguage),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. click_attendance (스펙 §2-3)
  // ---------------------------------------------------------------------------

  /// 출석체크 팝업에서 '출석하기' 버튼 클릭 시.
  ///
  /// [virtualCurrencyName] 예시값: `별사탕`, `보너스 별사탕`.
  Future<bool> logClickAttendance({
    required String? virtualCurrencyName,
    required num? rewardAmount,
  }) {
    return _log(
      Ga4Event.clickAttendance,
      strings: <String, String?>{
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
      },
      numbers: <String, num?>{
        Ga4Param.rewardAmount: rewardAmount,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. click_mission (스펙 §2-4)
  // ---------------------------------------------------------------------------

  /// 무료 충전소 '미션에서 별사탕 받기' 영역에서 미션 버튼 클릭 시.
  ///
  /// [missionCategory] 예시값: `글로벌 픽 #1`, `아시아 픽 #1`.
  Future<bool> logClickMission({
    required String? missionCategory,
  }) {
    return _log(
      Ga4Event.clickMission,
      strings: <String, String?>{
        Ga4Param.missionCategory: missionCategory,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ad_request (스펙 §2-5)
  // ---------------------------------------------------------------------------

  /// 무료 충전소 '광고에서 별사탕 받기' 영역에서 시청 버튼 클릭 시.
  ///
  /// [sectionName] 예시값: `광고에서 별사탕 받기`.
  Future<bool> logAdRequest({
    required String? sectionName,
    required String? adCategory,
    required String? virtualCurrencyName,
    required num? rewardAmount,
  }) {
    return _log(
      Ga4Event.adRequest,
      strings: <String, String?>{
        Ga4Param.sectionName: sectionName,
        Ga4Param.adCategory: adCategory,
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
      },
      numbers: <String, num?>{
        Ga4Param.rewardAmount: rewardAmount,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. ad_impression (스펙 §2-6)
  // ---------------------------------------------------------------------------

  /// 광고 SDK 가 실제 광고를 노출했을 때.
  ///
  /// **중복 집계 주의**: Firebase↔AdMob 연동이 켜져 있으면 SDK 가 동일한 이름의
  /// `ad_impression` 을 자동 수집한다. 스펙이 커스텀 파라미터
  /// (`section_name`, `ad_category`, `virtual_currency_name`, `reward_amount`)를
  /// 요구하므로 여기서는 스펙대로 커스텀 logEvent 를 수행하되, 리포트에서
  /// 노출 수가 2배로 보이면 자동수집/커스텀 중 한쪽을 정리해야 한다.
  Future<bool> logAdImpression({
    required String? adPlatform,
    required String? adSource,
    required String? adFormat,
    required String? adUnitName,
    required String? sectionName,
    required String? adCategory,
    required String? virtualCurrencyName,
    required num? rewardAmount,
  }) {
    return _log(
      Ga4Event.adImpression,
      strings: <String, String?>{
        Ga4Param.adPlatform: adPlatform,
        Ga4Param.adSource: adSource,
        Ga4Param.adFormat: adFormat,
        Ga4Param.adUnitName: adUnitName,
        Ga4Param.sectionName: sectionName,
        Ga4Param.adCategory: adCategory,
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
      },
      numbers: <String, num?>{
        Ga4Param.rewardAmount: rewardAmount,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 7. earn_virtual_currency (스펙 §2-7)
  // ---------------------------------------------------------------------------

  /// 광고를 끝까지 시청하여 별사탕이 실제 지급됐을 때.
  ///
  /// GA4 표준 `earn_virtual_currency` 는 수량을 `value` 로 받지만, 본 택소노미는
  /// `reward_amount` 로 정의한다(스펙 §2-7 주석). 그래서 Firebase 의
  /// `logEarnVirtualCurrency` 헬퍼를 쓰지 않고 raw logEvent 로 보낸다.
  ///
  /// [earnMethod] 예시값: `광고 리워드`.
  Future<bool> logEarnVirtualCurrency({
    required String? virtualCurrencyName,
    required num? rewardAmount,
    required String? earnMethod,
    required String? sectionName,
    required String? adCategory,
  }) {
    return _log(
      Ga4Event.earnVirtualCurrency,
      strings: <String, String?>{
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
        Ga4Param.earnMethod: earnMethod,
        Ga4Param.sectionName: sectionName,
        Ga4Param.adCategory: adCategory,
      },
      numbers: <String, num?>{
        Ga4Param.rewardAmount: rewardAmount,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 8. ad_cta_click (스펙 §2-8)
  // ---------------------------------------------------------------------------

  /// 광고 종료 후 '더보기' 버튼을 눌러 이동했을 때.
  ///
  /// [destinationType] 예시값: `youtube`.
  Future<bool> logAdCtaClick({
    required String? adPlatform,
    required String? adSource,
    required String? adFormat,
    required String? adUnitName,
    required String? sectionName,
    required String? adCategory,
    required String? destinationType,
  }) {
    return _log(
      Ga4Event.adCtaClick,
      strings: <String, String?>{
        Ga4Param.adPlatform: adPlatform,
        Ga4Param.adSource: adSource,
        Ga4Param.adFormat: adFormat,
        Ga4Param.adUnitName: adUnitName,
        Ga4Param.sectionName: sectionName,
        Ga4Param.adCategory: adCategory,
        Ga4Param.destinationType: destinationType,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 9. purchase (스펙 §2-9)
  // ---------------------------------------------------------------------------

  /// 결제를 완료하여 별사탕을 구매했을 때(통신 시점).
  ///
  /// items 배열이 필요하므로 raw logEvent 가 아니라 Firebase 의 `logPurchase`
  /// 를 사용한다. GA4 파라미터 맵은 String/num 값만 허용해서 배열을 실을 수 없다.
  /// `base_amount` / `bonus_amount` / `virtual_currency_name` 은
  /// AnalyticsEventItem 의 표준 필드가 아니므로 Item 의 parameters 맵으로 넣는다.
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) {
    return _guard(Ga4Event.purchase, () {
      final trimmedCurrency = currency?.trim();
      return _sink.logPurchase(
        // transaction_id 는 GA4 표준 필드라 'undefined' 대체 규칙을 그대로
        // 적용한다(빈 문자열을 보내면 Firebase 가 파라미터를 버린다).
        transactionId: Ga4Parameters.stringValue(transactionId),
        // currency 는 ISO 4217 코드만 유효하다. 'undefined' 를 넣으면 GA4 가
        // 이 purchase 의 매출 값을 통째로 무시하므로(Number 파라미터의
        // undefined 대체를 금지한 스펙 예외와 같은 논리), 모르면 생략한다.
        // durable outbox 경로(AnalyticsOutbox._dispatch)와 같은 동작이다.
        currency: (trimmedCurrency == null || trimmedCurrency.isEmpty)
            ? null
            : trimmedCurrency,
        value: value,
        items: items,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // 10. vote (스펙 §2-10)
  // ---------------------------------------------------------------------------

  /// 투표 팝업에서 '투표' 버튼 클릭 시.
  ///
  /// [voteStartDate] / [voteEndDate] 예시값 포맷: `2026.06.26`.
  ///
  /// [virtualCurrencyName] 은 [Ga4CurrencyNames] 의 값이어야 한다. 한 번의
  /// 투표가 재화 2~3종을 동시에 소모하면 [Ga4CurrencyNames.combined] 의 결합
  /// 라벨이 오고, [rewardAmount] 는 그 총합이다.
  ///
  /// [starCandyUsage] / [starCandyBonusUsage] / [cottonCandyUsage] 는 스펙 외
  /// 가산 확장이다(근거는 [Ga4Param.starCandyUsage] 문서). 결합 라벨만으로는
  /// 재화별 소모량을 복원할 수 없어서 함께 보낸다. 쓰이지 않은 재화는 null 로
  /// 넘겨 파라미터가 생략되게 한다 — 0 을 보내면 "쓰지 않았다"와 "쓸 수
  /// 있었는데 0 이었다"가 구분되지 않고, 문자열 `undefined` 는
  /// [Ga4Parameters.build] 문서대로 커스텀 측정항목 타입을 오염시킨다.
  Future<bool> logVote({
    required String? virtualCurrencyName,
    required num? rewardAmount,
    required String? voteId,
    required String? voteName,
    required String? voteReward,
    required String? voteStartDate,
    required String? voteEndDate,
    required String? voteArtistName,
    required String? voteArtistGroup,
    num? starCandyUsage,
    num? starCandyBonusUsage,
    num? cottonCandyUsage,
  }) {
    return _log(
      Ga4Event.vote,
      strings: <String, String?>{
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
        Ga4Param.voteId: voteId,
        Ga4Param.voteName: voteName,
        Ga4Param.voteReward: voteReward,
        Ga4Param.voteStartDate: voteStartDate,
        Ga4Param.voteEndDate: voteEndDate,
        Ga4Param.voteArtistName: voteArtistName,
        Ga4Param.voteArtistGroup: voteArtistGroup,
      },
      numbers: <String, num?>{
        Ga4Param.rewardAmount: rewardAmount,
        // 미사용 재화는 아예 맵에 담지 않는다(null-aware entry). null 을 담으면
        // Ga4Parameters 가 "호출부 버그" 경고를 남기는데, 안 쓴 재화는 버그가
        // 아니다.
        Ga4Param.starCandyUsage: ?starCandyUsage,
        Ga4Param.starCandyBonusUsage: ?starCandyBonusUsage,
        Ga4Param.cottonCandyUsage: ?cottonCandyUsage,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 내부
  // ---------------------------------------------------------------------------

  Future<bool> _log(
    String eventName, {
    required Map<String, String?> strings,
    Map<String, num?> numbers = const <String, num?>{},
  }) {
    return _guard(eventName, () {
      final name = Ga4Parameters.eventName(eventName);
      final parameters = Ga4Parameters.build(
        strings: strings,
        numbers: numbers,
        eventNameForLog: eventName,
      );
      return _sink.logEvent(name, parameters);
    });
  }

  /// 안전 래퍼: analytics 실패가 절대 앱을 죽이지 않게 하되, 조용히 삼키지 않는다.
  ///
  /// 예외를 잡는 것과 성공을 보고하는 것은 다르다. 던진 발송은 **`false`** 다.
  Future<bool> _guard(String what, Future<bool> Function() body) async {
    try {
      return await body();
    } catch (e, s) {
      logger.e('Analytics 처리 중 오류 ($what)', error: e, stackTrace: s);
      return false;
    }
  }
}
