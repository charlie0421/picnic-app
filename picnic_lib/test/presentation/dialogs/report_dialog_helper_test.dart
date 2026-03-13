import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog_helper.dart';

void main() {
  group('ReportDialogHelper', () {
    group('constants', () {
      test('otherReasonIndex is 4', () {
        expect(ReportDialogHelper.otherReasonIndex, 4);
      });

      test('defaultMaxLength is 100', () {
        expect(ReportDialogHelper.defaultMaxLength, 100);
      });
    });

    group('validateOtherReason', () {
      const emptyError = 'Please enter a reason';

      test('returns null when selectedReason is not otherReasonIndex', () {
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 0,
          text: '',
          emptyErrorMessage: emptyError,
        );
        expect(result, isNull);
      });

      test('returns null when selectedReason is null', () {
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: null,
          text: '',
          emptyErrorMessage: emptyError,
        );
        expect(result, isNull);
      });

      test('returns error message when text is empty and reason is other', () {
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: '',
          emptyErrorMessage: emptyError,
        );
        expect(result, emptyError);
      });

      test('returns error message when text is whitespace only', () {
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: '   ',
          emptyErrorMessage: emptyError,
        );
        expect(result, emptyError);
      });

      test('returns null when text is valid', () {
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: 'Valid reason text',
          emptyErrorMessage: emptyError,
        );
        expect(result, isNull);
      });

      test('returns error when text exceeds maxLength', () {
        final longText = 'a' * 101;
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: longText,
          maxLength: 100,
          emptyErrorMessage: emptyError,
        );
        expect(result, contains('100'));
      });

      test('returns null when text is exactly maxLength', () {
        final exactText = 'a' * 100;
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: exactText,
          maxLength: 100,
          emptyErrorMessage: emptyError,
        );
        expect(result, isNull);
      });

      test('returns error with custom maxLength', () {
        final longText = 'a' * 51;
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: longText,
          maxLength: 50,
          emptyErrorMessage: emptyError,
        );
        expect(result, contains('50'));
      });

      test('trims text before checking length', () {
        // Text with spaces that when trimmed is within limit
        final result = ReportDialogHelper.validateOtherReason(
          selectedReason: 4,
          text: '  short  ',
          maxLength: 10,
          emptyErrorMessage: emptyError,
        );
        expect(result, isNull);
      });

      test('returns null for non-other reasons even with invalid text', () {
        for (int i = 0; i < 4; i++) {
          final result = ReportDialogHelper.validateOtherReason(
            selectedReason: i,
            text: '',
            emptyErrorMessage: emptyError,
          );
          expect(result, isNull, reason: 'Reason $i should return null');
        }
      });
    });

    group('canSubmitReport', () {
      const noReasonMsg = 'Select a reason';
      const otherEmptyMsg = 'Enter other reason';

      test('returns invalid when no reason selected', () {
        final result = ReportDialogHelper.canSubmitReport(
          selectedReason: null,
          otherReasonText: '',
          noReasonSelectedMessage: noReasonMsg,
          otherReasonEmptyMessage: otherEmptyMsg,
        );
        expect(result.isValid, isFalse);
        expect(result.errorType, ReportValidationError.noReasonSelected);
        expect(result.errorMessage, noReasonMsg);
      });

      test('returns invalid when other reason selected but text empty', () {
        final result = ReportDialogHelper.canSubmitReport(
          selectedReason: 4,
          otherReasonText: '',
          noReasonSelectedMessage: noReasonMsg,
          otherReasonEmptyMessage: otherEmptyMsg,
        );
        expect(result.isValid, isFalse);
        expect(result.errorType, ReportValidationError.otherReasonEmpty);
        expect(result.errorMessage, otherEmptyMsg);
      });

      test('returns invalid when other reason text is whitespace', () {
        final result = ReportDialogHelper.canSubmitReport(
          selectedReason: 4,
          otherReasonText: '   ',
          noReasonSelectedMessage: noReasonMsg,
          otherReasonEmptyMessage: otherEmptyMsg,
        );
        expect(result.isValid, isFalse);
        expect(result.errorType, ReportValidationError.otherReasonEmpty);
      });

      test('returns valid when standard reason selected', () {
        for (int i = 0; i < 4; i++) {
          final result = ReportDialogHelper.canSubmitReport(
            selectedReason: i,
            otherReasonText: '',
            noReasonSelectedMessage: noReasonMsg,
            otherReasonEmptyMessage: otherEmptyMsg,
          );
          expect(result.isValid, isTrue, reason: 'Reason $i should be valid');
          expect(result.errorType, isNull);
          expect(result.errorMessage, isNull);
        }
      });

      test('returns valid when other reason has text', () {
        final result = ReportDialogHelper.canSubmitReport(
          selectedReason: 4,
          otherReasonText: 'Some reason',
          noReasonSelectedMessage: noReasonMsg,
          otherReasonEmptyMessage: otherEmptyMsg,
        );
        expect(result.isValid, isTrue);
      });
    });

    group('getReasonText', () {
      final reasons = ['Spam', 'Abuse', 'Inappropriate', 'Violence', 'Other'];

      test('returns correct reason for valid index', () {
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: 0),
          'Spam',
        );
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: 2),
          'Inappropriate',
        );
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: 4),
          'Other',
        );
      });

      test('returns empty string for negative index', () {
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: -1),
          '',
        );
      });

      test('returns empty string for out-of-bounds index', () {
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: 5),
          '',
        );
        expect(
          ReportDialogHelper.getReasonText(reasons: reasons, selectedIndex: 100),
          '',
        );
      });

      test('returns empty string for empty reasons list', () {
        expect(
          ReportDialogHelper.getReasonText(reasons: [], selectedIndex: 0),
          '',
        );
      });
    });

    group('shouldShowOtherReasonField', () {
      test('returns true for otherReasonIndex', () {
        expect(ReportDialogHelper.shouldShowOtherReasonField(4), isTrue);
      });

      test('returns false for other indices', () {
        expect(ReportDialogHelper.shouldShowOtherReasonField(0), isFalse);
        expect(ReportDialogHelper.shouldShowOtherReasonField(1), isFalse);
        expect(ReportDialogHelper.shouldShowOtherReasonField(2), isFalse);
        expect(ReportDialogHelper.shouldShowOtherReasonField(3), isFalse);
      });

      test('returns false for null', () {
        expect(ReportDialogHelper.shouldShowOtherReasonField(null), isFalse);
      });
    });

    group('shouldClearOtherReason', () {
      test('returns true for non-other reasons', () {
        expect(ReportDialogHelper.shouldClearOtherReason(0), isTrue);
        expect(ReportDialogHelper.shouldClearOtherReason(1), isTrue);
        expect(ReportDialogHelper.shouldClearOtherReason(2), isTrue);
        expect(ReportDialogHelper.shouldClearOtherReason(3), isTrue);
      });

      test('returns false for other reason', () {
        expect(ReportDialogHelper.shouldClearOtherReason(4), isFalse);
      });

      test('returns true for null', () {
        expect(ReportDialogHelper.shouldClearOtherReason(null), isTrue);
      });
    });
  });

  group('ReportValidationResult', () {
    test('valid result has no error', () {
      const result = ReportValidationResult(isValid: true);
      expect(result.isValid, isTrue);
      expect(result.errorType, isNull);
      expect(result.errorMessage, isNull);
    });

    test('invalid result with error type and message', () {
      const result = ReportValidationResult(
        isValid: false,
        errorType: ReportValidationError.noReasonSelected,
        errorMessage: 'Select a reason',
      );
      expect(result.isValid, isFalse);
      expect(result.errorType, ReportValidationError.noReasonSelected);
      expect(result.errorMessage, 'Select a reason');
    });
  });

  group('ReportValidationError', () {
    test('has expected values', () {
      expect(ReportValidationError.values.length, 2);
      expect(ReportValidationError.values,
          contains(ReportValidationError.noReasonSelected));
      expect(ReportValidationError.values,
          contains(ReportValidationError.otherReasonEmpty));
    });
  });
}
