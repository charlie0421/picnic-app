import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_input_helper.dart';

void main() {
  // ── validateInput ───────────────────────────────────────────────────
  group('validateInput', () {
    test('returns missingBirthDate when birthDate is null', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: null,
          gender: 'male',
          agreedToSaveProfile: true,
        ),
        GoonghapValidationError.missingBirthDate,
      );
    });

    test('returns missingGender when gender is null', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: DateTime(2000, 1, 1),
          gender: null,
          agreedToSaveProfile: true,
        ),
        GoonghapValidationError.missingGender,
      );
    });

    test('returns missingAgreement when not agreed', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: DateTime(2000, 1, 1),
          gender: 'female',
          agreedToSaveProfile: false,
        ),
        GoonghapValidationError.missingAgreement,
      );
    });

    test('returns null when all fields are valid', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: DateTime(2000, 1, 1),
          gender: 'male',
          agreedToSaveProfile: true,
        ),
        isNull,
      );
    });

    test('checks birthDate before gender', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: null,
          gender: null,
          agreedToSaveProfile: false,
        ),
        GoonghapValidationError.missingBirthDate,
      );
    });

    test('checks gender before agreement', () {
      expect(
        GoonghapInputHelper.validateInput(
          birthDate: DateTime(2000),
          gender: null,
          agreedToSaveProfile: false,
        ),
        GoonghapValidationError.missingGender,
      );
    });
  });

  // ── isSubmitEnabled ─────────────────────────────────────────────────
  group('isSubmitEnabled', () {
    test('returns true when not loading and agreed', () {
      expect(
        GoonghapInputHelper.isSubmitEnabled(
          isLoading: false,
          agreedToSaveProfile: true,
        ),
        true,
      );
    });

    test('returns false when loading', () {
      expect(
        GoonghapInputHelper.isSubmitEnabled(
          isLoading: true,
          agreedToSaveProfile: true,
        ),
        false,
      );
    });

    test('returns false when not agreed', () {
      expect(
        GoonghapInputHelper.isSubmitEnabled(
          isLoading: false,
          agreedToSaveProfile: false,
        ),
        false,
      );
    });

    test('returns false when both loading and not agreed', () {
      expect(
        GoonghapInputHelper.isSubmitEnabled(
          isLoading: true,
          agreedToSaveProfile: false,
        ),
        false,
      );
    });
  });

  // ── parseTimeSlot ───────────────────────────────────────────────────
  group('parseTimeSlot', () {
    test('parses full time slot with all parts', () {
      final parts = GoonghapInputHelper.parseTimeSlot('자시|23:00~01:00|🐀');
      expect(parts.text, '자시');
      expect(parts.time, '23:00~01:00');
      expect(parts.icon, '🐀');
    });

    test('parses time slot with two parts', () {
      final parts = GoonghapInputHelper.parseTimeSlot('축시|01:00~03:00');
      expect(parts.text, '축시');
      expect(parts.time, '01:00~03:00');
      expect(parts.icon, '');
    });

    test('parses time slot with one part', () {
      final parts = GoonghapInputHelper.parseTimeSlot('모름');
      expect(parts.text, '모름');
      expect(parts.time, '');
      expect(parts.icon, '');
    });

    test('handles empty string', () {
      final parts = GoonghapInputHelper.parseTimeSlot('');
      expect(parts.text, '');
      expect(parts.time, '');
      expect(parts.icon, '');
    });
  });

  // ── formatTimeSlotDisplay ───────────────────────────────────────────
  group('formatTimeSlotDisplay', () {
    test('formats with icon', () {
      expect(
        GoonghapInputHelper.formatTimeSlotDisplay('자시|23:00~01:00|🐀'),
        '🐀 자시 23:00~01:00',
      );
    });

    test('formats without icon', () {
      expect(
        GoonghapInputHelper.formatTimeSlotDisplay('축시|01:00~03:00'),
        '축시 01:00~03:00',
      );
    });

    test('formats single part', () {
      expect(
        GoonghapInputHelper.formatTimeSlotDisplay('모름'),
        '모름',
      );
    });
  });

  // ── getTimeSlotLabel ────────────────────────────────────────────────
  group('getTimeSlotLabel', () {
    final timeSlots = [
      '자시|23:00~01:00|🐀',
      '축시|01:00~03:00|🐂',
      '인시|03:00~05:00|🐅',
    ];

    test('returns label for valid index', () {
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '1'), '자시');
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '2'), '축시');
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '3'), '인시');
    });

    test('returns null for null birthTime', () {
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, null), isNull);
    });

    test('returns null for index out of range', () {
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '0'), isNull);
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '4'), isNull);
    });

    test('returns null for non-numeric birthTime', () {
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, 'abc'), isNull);
    });

    test('returns null for negative index', () {
      expect(GoonghapInputHelper.getTimeSlotLabel(timeSlots, '-1'), isNull);
    });
  });

  // ── getGenderDisplay ────────────────────────────────────────────────
  group('getGenderDisplay', () {
    test('returns male label for male', () {
      expect(
        GoonghapInputHelper.getGenderDisplay(
          gender: 'male',
          maleLabel: '남성',
          femaleLabel: '여성',
        ),
        '남성',
      );
    });

    test('returns female label for female', () {
      expect(
        GoonghapInputHelper.getGenderDisplay(
          gender: 'female',
          maleLabel: '남성',
          femaleLabel: '여성',
        ),
        '여성',
      );
    });

    test('returns raw value for unknown gender', () {
      expect(
        GoonghapInputHelper.getGenderDisplay(
          gender: 'other',
          maleLabel: '남성',
          femaleLabel: '여성',
        ),
        'other',
      );
    });
  });

  // ── isGenderSelected ────────────────────────────────────────────────
  group('isGenderSelected', () {
    test('returns true when selected', () {
      expect(GoonghapInputHelper.isGenderSelected('male', 'male'), true);
    });

    test('returns false when not selected', () {
      expect(GoonghapInputHelper.isGenderSelected('male', 'female'), false);
    });

    test('returns false when current is null', () {
      expect(GoonghapInputHelper.isGenderSelected(null, 'male'), false);
    });
  });

  // ── GoonghapValidationError enum ────────────────────────────────────
  group('GoonghapValidationError', () {
    test('has all expected values', () {
      expect(GoonghapValidationError.values.length, 3);
      expect(GoonghapValidationError.values, contains(GoonghapValidationError.missingBirthDate));
      expect(GoonghapValidationError.values, contains(GoonghapValidationError.missingGender));
      expect(GoonghapValidationError.values, contains(GoonghapValidationError.missingAgreement));
    });
  });

  // ── TimeSlotParts ───────────────────────────────────────────────────
  group('TimeSlotParts', () {
    test('stores values correctly', () {
      const parts = TimeSlotParts(text: 'T', time: '10:00', icon: '🐅');
      expect(parts.text, 'T');
      expect(parts.time, '10:00');
      expect(parts.icon, '🐅');
    });
  });
}
