import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_currency_names.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';

void main() {
  group('재화 이름의 진실의 원천은 Ga4CurrencyNames 하나다', () {
    test('모든 재화에서 Ga4CurrencyNames.of 와 값이 같다', () {
      // 두 곳이 각자 문자열을 들고 있으면 한쪽만 바뀌었을 때 같은 재화가
      // GA4 에서 두 디멘션 값으로 갈라진다.
      for (final currency in WalletCurrency.values) {
        expect(
          FreeChargeGa4.currencyName(currency),
          Ga4CurrencyNames.of(currency),
          reason: currency.name,
        );
      }
    });

    test('광고 리워드 재화는 코튼캔디 기준값을 그대로 쓴다', () {
      expect(FreeChargeGa4.adRewardCurrencyName, Ga4CurrencyNames.cottonCandy);
      expect(
        FreeChargeGa4.adRewardCurrencyName,
        FreeChargeGa4.currencyName(WalletCurrency.cottonCandy),
      );
    });

    test('free_charge_analytics.dart 에 재화 이름 리터럴이 남아 있지 않다', () {
      // 위 두 테스트는 값이 우연히 같기만 해도 통과한다. 여기서는 소스에서
      // 문자열 자체가 사라졌는지를 본다 — 리터럴이 다시 들어오면 값이 갈라질
      // 여지가 되살아난다.
      final source = File(
        'lib/presentation/widgets/vote/store/free_charge_station/'
        'free_charge_analytics.dart',
      ).readAsStringSync();

      for (final currency in WalletCurrency.values) {
        final literal = "'${Ga4CurrencyNames.of(currency)}'";
        expect(
          source.contains(literal),
          isFalse,
          reason: '$literal 을 직접 쓰지 말고 Ga4CurrencyNames 에 위임하라',
        );
      }
    });
  });
}
