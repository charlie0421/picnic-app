import 'package:flutter/foundation.dart';

/// Pure helper functions for FAQPage logic.
///
/// All methods are static and have no Flutter/widget dependencies,
/// making them easy to unit test.
@visibleForTesting
class FAQPageHelper {
  FAQPageHelper._();

  /// Returns the localized text from a JSON map for the given [language].
  /// Falls back to 'en' if the requested language is not available.
  @visibleForTesting
  static String getLocalizedText(Map<String, dynamic> json, String language) {
    if (json[language] != null) {
      return json[language];
    }
    return json['en'] ?? '';
  }

  /// Returns the localized Delta from [answerDelta] for the given [language].
  /// Falls back to 'ko' if the requested language is not available.
  @visibleForTesting
  static Map<String, dynamic>? getLocalizedDelta(
    Map<String, dynamic>? answerDelta,
    String language,
  ) {
    if (answerDelta == null) return null;
    if (answerDelta[language] != null) {
      return answerDelta[language] as Map<String, dynamic>?;
    }
    if (answerDelta['ko'] != null) {
      return answerDelta['ko'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Extracts plain text from a Quill Delta JSON structure (fallback renderer).
  @visibleForTesting
  static String extractPlainTextFromDelta(Map<String, dynamic> delta) {
    final ops = delta['ops'] as List?;
    if (ops == null) return '';
    return ops
        .where((op) => op is Map && op['insert'] is String)
        .map((op) => op['insert'] as String)
        .join();
  }

  /// Filters FAQs by [selectedCategory]. Returns all FAQs when category is 'ALL'.
  @visibleForTesting
  static List<Map<String, dynamic>> getFilteredFaqs(
    List<Map<String, dynamic>> faqs,
    String? selectedCategory,
  ) {
    if (selectedCategory == null || selectedCategory == 'ALL') {
      return faqs;
    }
    return faqs
        .where((faq) => faq['category'] == selectedCategory)
        .toList();
  }

  /// Builds the categories list from raw categories response data.
  /// Always prepends 'ALL' as the first entry.
  @visibleForTesting
  static List<String> buildCategoriesList(
    List<Map<String, dynamic>> categoriesData,
  ) {
    return [
      'ALL',
      ...categoriesData.map((e) => e['code']).whereType<String>(),
    ];
  }

  /// Returns the localized label for a category code.
  /// For 'ALL', returns the provided [allLabel].
  /// Looks up the category in [categoriesData] and returns the localized label.
  /// Falls back to returning the [categoryCode] itself.
  @visibleForTesting
  static String getLocalizedCategoryLabel(
    String categoryCode,
    String language,
    List<Map<String, dynamic>> categoriesData, {
    required String allLabel,
  }) {
    if (categoryCode == 'ALL') {
      return allLabel;
    }
    try {
      final Map<String, dynamic> found = categoriesData.firstWhere(
        (c) => c['code'] == categoryCode,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty && found['label'] is Map<String, dynamic>) {
        return getLocalizedText(
          found['label'] as Map<String, dynamic>,
          language,
        );
      }
    } catch (_) {}
    return categoryCode;
  }
}
