import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure validation helpers extracted from [BoardRequest] for testability.
///
/// These methods return `null` when valid, or a non-null error key
/// (the raw validation reason) when invalid.
class BoardRequestHelper {
  const BoardRequestHelper._();

  /// Validates a board name. Must be non-empty.
  @visibleForTesting
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'empty';
    return null;
  }

  /// Validates a board description.
  /// Must be non-empty and between 5-20 characters.
  @visibleForTesting
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'empty';
    if (value.length < 5 || value.length > 20) return 'length';
    return null;
  }

  /// Validates a request message.
  /// Must be non-empty and at least 10 characters.
  @visibleForTesting
  static String? validateRequestMessage(String? value) {
    if (value == null || value.isEmpty) return 'empty';
    if (value.length < 10) return 'length';
    return null;
  }

  /// Returns whether all three fields are valid.
  @visibleForTesting
  static bool isFormValid(String name, String description, String requestMessage) {
    return validateName(name) == null &&
        validateDescription(description) == null &&
        validateRequestMessage(requestMessage) == null;
  }
}
