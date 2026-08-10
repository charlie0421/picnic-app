/// GA4 로 내보내는 언어 코드의 **유일한 정규화 지점**.
///
/// ## 왜 필요한가
///
/// 앱 내부의 언어 코드는 ISO 639-1 기준이라 일본어가 `ja` 다
/// (`core/constatns/constants.dart` 의 `languageMap`/`countryMap`,
/// `AppLocalizations.supportedLocales`). 그런데 택소노미 스펙
/// (`docs/analytics/ga4-event-taxonomy.md` §1, §2-1, §2-2)은 `language` /
/// `selected_language` 의 예시값을 `ko`, `en`, **`jp`** 로 정의한다.
///
/// 앱 값을 그대로 보내면 대행사 리포트가 기대하는 `jp` 로 잡히는 세그먼트가
/// 통째로 비고, 일본어 사용자가 리포트에서 사라진다.
///
/// ## 왜 analytics 경계에서만 바꾸는가
///
/// `ja` 는 ARB 파일명·`Locale`·`SharedPreferences` 에 저장된 설정값까지
/// 전부를 관통하는 **앱의 실제 언어 코드**다. 이걸 `jp` 로 바꾸면 로케일 해석과
/// 저장된 설정 마이그레이션이 통째로 깨진다. 그래서 앱 내부는 손대지 않고,
/// GA4 로 나가는 마지막 지점([PicnicAnalytics])에서만 표기를 바꾼다.
///
/// 정규화를 [PicnicAnalytics] 안에 두는 이유는 호출부가 3곳
/// (`app_initializer` / `app_builder` / `main_initializer`)이라, 호출부마다
/// 변환하면 한 곳을 빠뜨렸을 때 같은 사용자가 `ja` 와 `jp` 두 값으로 갈라지기
/// 때문이다.
abstract final class Ga4Language {
  /// 앱 언어 코드 → 스펙 표기.
  ///
  /// 여기에 없는 코드는 **그대로 통과시킨다.** 스펙은 `ko`/`en`/`jp` 세 개만
  /// 예시로 적고 나머지 9개 지원 언어(`es`, `zh_CN`, `zh_TW`, `id`, `bn_BD`,
  /// `fil`, `th`, `vi`, `my`)에 대해서는 아무 규정이 없다. 규정 없는 값을
  /// 임의로 손대면(예: 소문자화, `_`→`-`) 이미 수집 중인 GA4 히스토리와
  /// 단절되므로, 스펙이 명시적으로 다르게 적은 것만 바꾼다.
  static const Map<String, String> overrides = <String, String>{
    'ja': 'jp',
  };

  /// GA4 로 보낼 언어 코드를 돌려준다.
  ///
  /// null·공백은 null 로 돌려 호출부가 "값 없음"으로 처리하게 한다(스펙의
  /// `undefined` 규칙은 상위 파라미터 레이어가 적용한다).
  ///
  /// 매핑 조회는 대소문자를 무시하지만(`JA` → `jp`), 매핑에 없는 코드는
  /// 원문 그대로 돌려준다 — `zh_CN` 을 `zh_cn` 으로 바꾸지 않기 위해서다.
  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return overrides[trimmed.toLowerCase()] ?? trimmed;
  }
}
