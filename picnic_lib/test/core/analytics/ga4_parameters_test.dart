import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_parameters.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';

void main() {
  group('Ga4Parameters.stringValue', () {
    test('null 은 undefined 로 대체된다', () {
      expect(Ga4Parameters.stringValue(null), Ga4Value.undefined);
    });

    test('빈 문자열과 공백만 있는 문자열도 undefined 로 대체된다', () {
      expect(Ga4Parameters.stringValue(''), Ga4Value.undefined);
      expect(Ga4Parameters.stringValue('   '), Ga4Value.undefined);
    });

    test('스프레드시트 한글 예시값을 그대로 보존한다 (슬러그 정규화 금지)', () {
      expect(Ga4Parameters.stringValue('별사탕'), '별사탕');
      expect(Ga4Parameters.stringValue('보너스 별사탕'), '보너스 별사탕');
      expect(Ga4Parameters.stringValue('광고에서 별사탕 받기'), '광고에서 별사탕 받기');
      expect(Ga4Parameters.stringValue('글로벌 픽 #1'), '글로벌 픽 #1');
      expect(Ga4Parameters.stringValue('광고 리워드'), '광고 리워드');
    });

    test('100자 이하는 그대로 둔다', () {
      final exact = 'a' * Ga4Limits.maxStringValueLength;
      expect(Ga4Parameters.stringValue(exact), exact);
      expect(Ga4Parameters.stringValue(exact).length,
          Ga4Limits.maxStringValueLength);
    });

    test('100자 초과 문자열 값은 100자로 잘린다', () {
      final long = 'x' * 250;
      final result = Ga4Parameters.stringValue(long);
      expect(result.length, Ga4Limits.maxStringValueLength);
      expect(result, 'x' * Ga4Limits.maxStringValueLength);
    });
  });

  group('Ga4Parameters.eventName / parameterName', () {
    test('40자 이하 이름은 그대로 둔다', () {
      expect(Ga4Parameters.eventName(Ga4Event.earnVirtualCurrency),
          Ga4Event.earnVirtualCurrency);
      expect(Ga4Parameters.parameterName(Ga4Param.virtualCurrencyName),
          Ga4Param.virtualCurrencyName);
    });

    test('40자 초과 이벤트 이름은 40자로 잘린다', () {
      final long = 'e' * 55;
      expect(Ga4Parameters.eventName(long).length,
          Ga4Limits.maxEventNameLength);
    });

    test('40자 초과 파라미터 이름은 40자로 잘린다', () {
      final long = 'p' * 41;
      expect(Ga4Parameters.parameterName(long).length,
          Ga4Limits.maxParameterNameLength);
    });

    test('스펙에 정의된 모든 이벤트 이름이 GA4 40자 제한 안에 있다', () {
      for (final name in Ga4Event.all) {
        expect(name.length, lessThanOrEqualTo(Ga4Limits.maxEventNameLength),
            reason: '이벤트 이름 $name 이 40자를 초과한다');
      }
    });
  });

  group('Ga4Parameters.build', () {
    test('String 파라미터는 값이 없어도 undefined 로 항상 포함된다', () {
      final params = Ga4Parameters.build(
        strings: <String, String?>{
          Ga4Param.method: null,
          Ga4Param.selectedLanguage: '',
        },
      );

      expect(params.keys, containsAll(<String>[
        Ga4Param.method,
        Ga4Param.selectedLanguage,
      ]));
      expect(params[Ga4Param.method], Ga4Value.undefined);
      expect(params[Ga4Param.selectedLanguage], Ga4Value.undefined);
    });

    test('Number 파라미터는 값이 있으면 num 타입 그대로 실린다', () {
      final params = Ga4Parameters.build(
        strings: const <String, String?>{},
        numbers: const <String, num?>{Ga4Param.rewardAmount: 60},
      );

      expect(params[Ga4Param.rewardAmount], 60);
      expect(params[Ga4Param.rewardAmount], isA<num>());
    });

    test('Number 파라미터는 값이 없으면 생략된다 (GA4 커스텀 측정항목 타입 오염 방지)', () {
      final params = Ga4Parameters.build(
        strings: const <String, String?>{},
        numbers: const <String, num?>{Ga4Param.rewardAmount: null},
        eventNameForLog: Ga4Event.vote,
      );

      expect(params.containsKey(Ga4Param.rewardAmount), isFalse);
      // 문자열 undefined 로 들어가지 않는다는 점이 핵심이다.
      expect(params.values, isNot(contains(Ga4Value.undefined)));
    });

    test('모든 값은 String 또는 num 이다 (GA4 파라미터 값 제약)', () {
      final params = Ga4Parameters.build(
        strings: <String, String?>{Ga4Param.virtualCurrencyName: '별사탕'},
        numbers: const <String, num?>{Ga4Param.rewardAmount: 1.5},
      );

      for (final value in params.values) {
        expect(value is String || value is num, isTrue,
            reason: '$value 는 GA4 가 허용하지 않는 타입이다');
      }
    });

    test('긴 값과 긴 파라미터 이름이 동시에 정규화된다', () {
      final params = Ga4Parameters.build(
        strings: <String, String?>{'n' * 60: 'v' * 200},
      );

      final key = params.keys.single;
      expect(key.length, Ga4Limits.maxParameterNameLength);
      expect((params[key] as String).length, Ga4Limits.maxStringValueLength);
    });
  });
}
