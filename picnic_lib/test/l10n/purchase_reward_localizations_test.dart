import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

void main() {
  test('uses a natural Base Bonus label in every supported locale', () async {
    final expected = <Locale, String>{
      Locale('bn'): 'মূল বোনাস',
      Locale('bn', 'BD'): 'মূল বোনাস',
      Locale('en'): 'Base bonus',
      Locale('es'): 'Bonificación base',
      Locale('fil'): 'Batayang bonus',
      Locale('id'): 'Bonus dasar',
      Locale('ja'): '基本ボーナス',
      Locale('ko'): '기본 보너스',
      Locale('my'): 'အခြေခံ ဘောနပ်စ်',
      Locale('th'): 'โบนัสพื้นฐาน',
      Locale('vi'): 'Thưởng cơ bản',
      Locale('zh'): '基础奖励',
      Locale('zh', 'CN'): '基础奖励',
      Locale('zh', 'TW'): '基本獎勵',
    };

    expect(expected.keys.toSet(), AppLocalizations.supportedLocales.toSet());
    for (final entry in expected.entries) {
      final l10n = await AppLocalizations.delegate.load(entry.key);
      expect(
        l10n.purchase_reward_product_bonus,
        entry.value,
        reason: entry.key.toLanguageTag(),
      );
    }
  });
}
