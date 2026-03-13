/// Pure logic helpers extracted from [GoonghapInputPage] for testability.
///
/// All methods are static and free of widget/state dependencies.
class GoonghapInputHelper {
  GoonghapInputHelper._();

  /// Determine which validation field is missing (if any).
  ///
  /// Returns the [GoonghapValidationError] for the first missing field,
  /// or `null` if all fields are valid.
  static GoonghapValidationError? validateInput({
    required DateTime? birthDate,
    required String? gender,
    required bool agreedToSaveProfile,
  }) {
    if (birthDate == null) return GoonghapValidationError.missingBirthDate;
    if (gender == null) return GoonghapValidationError.missingGender;
    if (!agreedToSaveProfile) return GoonghapValidationError.missingAgreement;
    return null;
  }

  /// Whether the submit button should be enabled.
  ///
  /// Disabled when loading or when the user hasn't agreed to save profile.
  static bool isSubmitEnabled({
    required bool isLoading,
    required bool agreedToSaveProfile,
  }) {
    return !isLoading && agreedToSaveProfile;
  }

  /// Parse a time slot string of the form "label|time|icon".
  ///
  /// Returns a [TimeSlotParts] record with the parsed values.
  static TimeSlotParts parseTimeSlot(String timeSlot) {
    final parts = timeSlot.split('|');
    final text = parts[0];
    final textTime = parts.length > 1 ? parts[1] : '';
    final icon = parts.length > 2 ? parts[2] : '';
    return TimeSlotParts(text: text, time: textTime, icon: icon);
  }

  /// Format a time slot for display (icon + text + time).
  static String formatTimeSlotDisplay(String timeSlot) {
    final parts = parseTimeSlot(timeSlot);
    final prefix = parts.icon.isNotEmpty ? '${parts.icon} ' : '';
    return '$prefix${parts.text} ${parts.time}'.trim();
  }

  /// Get the time slot display text for a given birth time index (1-based)
  /// from a list of time slot strings.
  ///
  /// Returns null if the index is out of range.
  static String? getTimeSlotLabel(List<String> timeSlots, String? birthTime) {
    if (birthTime == null) return null;
    final index = int.tryParse(birthTime);
    if (index == null || index < 1 || index > timeSlots.length) return null;
    final parts = parseTimeSlot(timeSlots[index - 1]);
    return parts.text;
  }

  /// Determine the gender display text.
  ///
  /// Returns [maleLabel] for 'male', [femaleLabel] for 'female',
  /// or the raw [gender] value as fallback.
  static String getGenderDisplay({
    required String gender,
    required String maleLabel,
    required String femaleLabel,
  }) {
    if (gender == 'male') return maleLabel;
    if (gender == 'female') return femaleLabel;
    return gender;
  }

  /// Whether a given gender value is selected.
  static bool isGenderSelected(String? currentGender, String value) {
    return currentGender == value;
  }
}

/// Validation errors for GoonghapInputPage.
enum GoonghapValidationError {
  missingBirthDate,
  missingGender,
  missingAgreement,
}

/// Parsed parts of a time slot string.
class TimeSlotParts {
  final String text;
  final String time;
  final String icon;

  const TimeSlotParts({
    required this.text,
    required this.time,
    required this.icon,
  });
}
