import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from ReportDialog.
/// These methods were extracted from _ReportDialogState to enable unit testing.
class ReportDialogHelper {
  /// The index of the "Other" reason option.
  static const int otherReasonIndex = 4;

  /// Default max character length for the other reason text field.
  static const int defaultMaxLength = 100;

  /// Validates the "other reason" text field.
  /// Returns an error message string if invalid, or null if valid.
  ///
  /// [selectedReason] - the currently selected reason index
  /// [text] - the trimmed text from the other reason controller
  /// [maxLength] - maximum allowed characters
  /// [emptyErrorMessage] - message to show when text is empty
  @visibleForTesting
  static String? validateOtherReason({
    required int? selectedReason,
    required String text,
    int maxLength = defaultMaxLength,
    required String emptyErrorMessage,
  }) {
    if (selectedReason != otherReasonIndex) return null;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return emptyErrorMessage;
    } else if (trimmed.length > maxLength) {
      return '최대 ${maxLength}자까지 입력 가능합니다.';
    }
    return null;
  }

  /// Checks whether the report can be submitted.
  /// Returns a [ReportValidationResult] indicating whether submission is valid
  /// and what error occurred if not.
  @visibleForTesting
  static ReportValidationResult canSubmitReport({
    required int? selectedReason,
    required String otherReasonText,
    required String noReasonSelectedMessage,
    required String otherReasonEmptyMessage,
  }) {
    if (selectedReason == null) {
      return ReportValidationResult(
        isValid: false,
        errorType: ReportValidationError.noReasonSelected,
        errorMessage: noReasonSelectedMessage,
      );
    }

    if (selectedReason == otherReasonIndex &&
        otherReasonText.trim().isEmpty) {
      return ReportValidationResult(
        isValid: false,
        errorType: ReportValidationError.otherReasonEmpty,
        errorMessage: otherReasonEmptyMessage,
      );
    }

    return const ReportValidationResult(isValid: true);
  }

  /// Builds the reason string for submission.
  /// Returns the reason from the list at the given index.
  @visibleForTesting
  static String getReasonText({
    required List<String> reasons,
    required int selectedIndex,
  }) {
    if (selectedIndex < 0 || selectedIndex >= reasons.length) {
      return '';
    }
    return reasons[selectedIndex];
  }

  /// Determines whether the "other reason" text field should be visible.
  @visibleForTesting
  static bool shouldShowOtherReasonField(int? selectedReason) {
    return selectedReason == otherReasonIndex;
  }

  /// Handles reason selection change.
  /// Returns whether the other reason field should be cleared.
  @visibleForTesting
  static bool shouldClearOtherReason(int? newValue) {
    return newValue != otherReasonIndex;
  }
}

/// Result of validating a report submission.
class ReportValidationResult {
  final bool isValid;
  final ReportValidationError? errorType;
  final String? errorMessage;

  const ReportValidationResult({
    required this.isValid,
    this.errorType,
    this.errorMessage,
  });
}

/// Types of validation errors for report submission.
enum ReportValidationError {
  noReasonSelected,
  otherReasonEmpty,
}
