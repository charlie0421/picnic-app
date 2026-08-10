import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// GA4 가 강제하는 길이 제한.
///
/// 초과분은 서버에서 **이벤트/파라미터 통째로 폐기**되므로, 조용히 유실되지
/// 않도록 클라이언트에서 미리 잘라내고 경고 로그를 남긴다.
/// https://support.google.com/analytics/answer/9267744
class Ga4Limits {
  const Ga4Limits._();

  static const int maxEventNameLength = 40;
  static const int maxParameterNameLength = 40;
  static const int maxStringValueLength = 100;
}

/// 스펙 §2 의 "정보가 없는 경우 값은 `undefined` 로 대체한다" 규칙과
/// GA4 길이 제한을 한 곳에서 강제하는 빌더.
class Ga4Parameters {
  const Ga4Parameters._();

  /// 이벤트 이름을 GA4 제한(40자)에 맞춰 정규화한다.
  static String eventName(String name) => _truncate(
        name,
        Ga4Limits.maxEventNameLength,
        'GA4 이벤트 이름',
      );

  /// 파라미터 이름을 GA4 제한(40자)에 맞춰 정규화한다.
  static String parameterName(String name) => _truncate(
        name,
        Ga4Limits.maxParameterNameLength,
        'GA4 파라미터 이름',
      );

  /// String 파라미터 값을 정규화한다.
  ///
  /// - null 또는 공백뿐인 값 → `'undefined'` (스펙 §2 대체 규칙).
  ///   파라미터 자체를 생략하지 않는다. 대행사 리포트가 "값 없음"을
  ///   `undefined` 라는 하나의 구간으로 세기 때문이다.
  /// - 100자 초과 → 잘라내고 경고 로그.
  static String stringValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return Ga4Value.undefined;
    return _truncate(raw, Ga4Limits.maxStringValueLength, 'GA4 파라미터 값');
  }

  /// 스펙에 정의된 이벤트 파라미터 맵을 만든다.
  ///
  /// [strings] 는 값이 없으면 `'undefined'` 로 대체해 **항상 포함**한다.
  ///
  /// [numbers] 는 값이 없으면 **파라미터를 생략**한다. 스프레드시트의
  /// `undefined` 대체 규칙을 Number 타입에 그대로 적용하지 않는 이유:
  ///
  ///   GA4 는 커스텀 파라미터 키를 처음 관측된 타입에 따라 커스텀
  ///   측정기준(text) 또는 커스텀 측정항목(number) 중 하나로만 등록한다.
  ///   `reward_amount` 에 숫자 60 과 문자열 `'undefined'` 를 섞어 보내면
  ///   등록된 타입과 다른 쪽 값이 리포트에서 통째로 누락된다. 즉 "누락을
  ///   표시하려다 정상 값까지 잃는" 교환이 된다. 따라서 Number 파라미터는
  ///   값이 없을 때 생략하고, 대신 경고 로그로 호출부의 버그를 드러낸다.
  ///   (이 결정은 docs/analytics/ga4-event-taxonomy.md 의 '대행사 확인 필요'
  ///   섹션에 기록되어 있다.)
  ///
  /// GA4 파라미터 값은 String 또는 num 만 허용하므로 반환 타입은
  /// `Map<String, Object>` 로 고정한다.
  static Map<String, Object> build({
    required Map<String, String?> strings,
    Map<String, num?> numbers = const <String, num?>{},
    String? eventNameForLog,
  }) {
    final parameters = <String, Object>{};

    strings.forEach((name, raw) {
      parameters[parameterName(name)] = stringValue(raw);
    });

    numbers.forEach((name, raw) {
      if (raw == null) {
        logger.w(
          'GA4 Number 파라미터 누락으로 생략: '
          'event=${eventNameForLog ?? '(unknown)'}, param=$name. '
          '문자열 undefined 대체는 GA4 커스텀 측정항목 타입을 오염시키므로 생략한다.',
        );
        return;
      }
      parameters[parameterName(name)] = raw;
    });

    return parameters;
  }

  static String _truncate(String raw, int max, String what) {
    if (raw.length <= max) return raw;
    final truncated = raw.substring(0, max);
    logger.w('$what 이(가) $max자를 초과해 잘라냈습니다: "$raw" -> "$truncated"');
    return truncated;
  }
}
