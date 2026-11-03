import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/iso_4217_currency.dart';

void main() {
  group('normalizeIso4217', () {
    test('accepts the currencies Picnic actually bills in', () {
      expect(normalizeIso4217('KRW'), 'KRW');
      expect(normalizeIso4217('USD'), 'USD');
      expect(normalizeIso4217('JPY'), 'JPY');
      expect(normalizeIso4217('EUR'), 'EUR');
      expect(normalizeIso4217('TWD'), 'TWD');
    });

    test('normalises case and surrounding whitespace', () {
      expect(normalizeIso4217('krw'), 'KRW');
      expect(normalizeIso4217(' usd '), 'USD');
      expect(normalizeIso4217('Jpy'), 'JPY');
    });

    test('rejects language codes and other near-misses', () {
      // 'ja' 는 GA4 언어 정규화 쪽 값이지 통화가 아니다. 이 관문이 없으면
      // 언어 코드가 통화 자리에 들어가도 조용히 통과한다.
      expect(normalizeIso4217('ja'), isNull);
      expect(normalizeIso4217('ko'), isNull);
      expect(normalizeIso4217('KR'), isNull);
      expect(normalizeIso4217('KRWW'), isNull);
      expect(normalizeIso4217('원'), isNull);
    });

    test('rejects empty, non-string and null input', () {
      expect(normalizeIso4217(null), isNull);
      expect(normalizeIso4217(''), isNull);
      expect(normalizeIso4217('   '), isNull);
      expect(normalizeIso4217(1000), isNull);
      expect(normalizeIso4217(<String>['KRW']), isNull);
    });

    test('rejects ISO codes that are registered but never a payment currency', () {
      // 전부 ISO 4217 에 있지만 매출 통화가 아니다. 통과시키면 GA4 매출
      // 리포트에 결제가 아닌 것이 섞인다.
      expect(normalizeIso4217('XXX'), isNull, reason: '거래 통화 없음');
      expect(normalizeIso4217('XTS'), isNull, reason: '테스트 전용 코드');
      expect(normalizeIso4217('XAU'), isNull, reason: '금');
      expect(normalizeIso4217('XDR'), isNull, reason: 'IMF 특별인출권');
      expect(normalizeIso4217('USN'), isNull, reason: '펀드 코드');
    });

    test('keeps the X-prefixed codes that really are regional currencies', () {
      expect(normalizeIso4217('XAF'), 'XAF');
      expect(normalizeIso4217('XOF'), 'XOF');
      expect(normalizeIso4217('XPF'), 'XPF');
      expect(normalizeIso4217('XCD'), 'XCD');
    });
  });

  test('isIso4217 agrees with normalizeIso4217', () {
    expect(isIso4217('krw'), isTrue);
    expect(isIso4217('ja'), isFalse);
    expect(isIso4217(null), isFalse);
  });

  test('every vendored code is three uppercase letters', () {
    final shape = RegExp(r'^[A-Z]{3}$');
    for (final code in iso4217CurrencyCodes) {
      expect(shape.hasMatch(code), isTrue, reason: '$code 는 ISO 4217 모양이 아니다');
    }
  });
}
