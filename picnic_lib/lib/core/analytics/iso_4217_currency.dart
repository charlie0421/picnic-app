/// GA4 매출 이벤트에 들어갈 수 있는 통화 코드의 단일 관문.
///
/// GA4 는 `purchase` 의 `currency` 가 ISO 4217 코드가 아니면 **그 거래의 매출을
/// 통째로 무시한다.** 값이 없는 것과 값이 틀린 것의 결과가 같으므로, 통화는
/// 보내기 직전에 한 번 더 검사한다.
///
/// 목록은 vendored 다 — 런타임 조회나 플랫폼 API 에 의존하지 않는다. GA4 로
/// 나가는 값이 기기 로케일 설정이나 스토어 SDK 버전에 따라 달라지면 안 되고,
/// 이 판단은 네트워크 없이 sink 직전에도 실행돼야 하기 때문이다.
library;

/// 결제 통화로 쓰일 수 있는 ISO 4217 코드.
///
/// 다음은 의도적으로 제외한다 — 전부 ISO 4217 에 등재돼 있지만 스토어 결제
/// 통화가 될 수 없고, 매출 리포트에 들어가면 오염이다.
///
/// * `XXX`(거래 통화 없음), `XTS`(테스트 전용) — 이름 그대로 매출이 아니다.
/// * `XAU`/`XAG`/`XPT`/`XPD`(귀금속), `XBA`~`XBD`(유럽 복합 단위),
///   `XDR`/`XSU`/`XUA`(초국가 계정 단위) — 결제 수단이 아니다.
/// * `BOV`/`CHE`/`CHW`/`CLF`/`COU`/`MXV`/`USN`/`UYI`/`UYW`(펀드 코드) —
///   실제 결제가 아니라 회계 단위다.
///
/// `XAF`/`XOF`/`XPF`/`XCD`/`XCG` 는 X 로 시작하지만 실제 지역 통화라 포함한다.
const Set<String> iso4217CurrencyCodes = <String>{
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', //
  'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL',
  'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY',
  'COP', 'CRC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP',
  'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GHS', 'GIP', 'GMD',
  'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HTG', 'HUF', 'IDR', 'ILS', 'INR',
  'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF',
  'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL',
  'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRU', 'MUR',
  'MVR', 'MWK', 'MXN', 'MYR', 'MZN', 'NAD', 'NGN', 'NIO', 'NOK', 'NPR',
  'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR',
  'RON', 'RSD', 'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD',
  'SHP', 'SLE', 'SOS', 'SRD', 'SSP', 'STN', 'SVC', 'SYP', 'SZL', 'THB',
  'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TWD', 'TZS', 'UAH', 'UGX',
  'USD', 'UYU', 'UZS', 'VED', 'VES', 'VND', 'VUV', 'WST', 'XAF', 'XCD',
  'XCG', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWG',
};

/// 통화 코드를 정규화한다. 매출 통화로 쓸 수 없으면 `null`.
///
/// 앞뒤 공백을 걷어내고 대문자로 올린 뒤 목록과 대조한다. 서버 snapshot,
/// 클라이언트 storefront, 스토어 카탈로그 — 출처가 무엇이든 GA4 payload 로
/// 들어가기 전에 반드시 이 함수를 통과해야 한다.
String? normalizeIso4217(Object? raw) {
  if (raw is! String) return null;
  final normalized = raw.trim().toUpperCase();
  if (normalized.length != 3) return null;
  return iso4217CurrencyCodes.contains(normalized) ? normalized : null;
}

/// [normalizeIso4217] 이 값을 돌려주는지 여부.
bool isIso4217(Object? raw) => normalizeIso4217(raw) != null;
