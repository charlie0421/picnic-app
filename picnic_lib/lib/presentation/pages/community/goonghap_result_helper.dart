import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure-logic helpers extracted from [GoonghapResultContent] for testability.
class GoonghapResultHelper {
  const GoonghapResultHelper._();

  /// Normalizes a language code for goonghap locale lookups.
  ///
  /// For Chinese locales, appends the country code (e.g. 'zh-CN', 'zh-TW').
  /// For all other languages, returns the base language code as-is.
  @visibleForTesting
  static String normalizeLanguageCode(String languageCode, String countryCode) {
    final language = languageCode.toLowerCase();
    final country = countryCode.toUpperCase();

    if (language == 'zh') {
      if (country == 'CN') return 'zh-CN';
      if (country == 'TW') return 'zh-TW';
    }
    return language;
  }

  /// Checks whether a purchase action should be allowed based on cooldown.
  ///
  /// Returns `true` if enough time has passed since [lastPurchaseTime],
  /// or if [lastPurchaseTime] is null (first purchase).
  @visibleForTesting
  static bool canPurchase(DateTime? lastPurchaseTime, Duration cooldown) {
    if (lastPurchaseTime == null) return true;
    final elapsed = DateTime.now().difference(lastPurchaseTime);
    return elapsed >= cooldown;
  }
}
