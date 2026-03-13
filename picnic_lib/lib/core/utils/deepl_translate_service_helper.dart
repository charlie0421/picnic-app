import 'package:flutter/foundation.dart';

@visibleForTesting
class DeepLTranslateServiceHelper {
  static final RegExp placeholderRegex = RegExp(r'\{[^}]+\}');

  /// Extracts placeholders from text and returns a map of temp keys to original placeholders.
  static Map<String, String> buildPlaceholderMap(String text) {
    final placeholders =
        placeholderRegex.allMatches(text).map((m) => m.group(0)!).toList();
    return Map.fromIterables(
      placeholders.map((p) => '__PH${placeholders.indexOf(p)}__'),
      placeholders,
    );
  }

  /// Replaces placeholders in text with temporary keys using the given map.
  static String replacePlaceholdersWithKeys(
      String text, Map<String, String> placeholderMap) {
    String result = text;
    placeholderMap.forEach((key, value) {
      result = result.replaceAll(value, key);
    });
    return result;
  }

  /// Restores original placeholders from temporary keys using the given map.
  static String restorePlaceholders(
      String text, Map<String, String> placeholderMap) {
    String result = text;
    placeholderMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  /// Determines if retries should continue based on attempt count and max attempts.
  static bool shouldRetry(int attempts, int maxAttempts) {
    return attempts < maxAttempts;
  }
}
