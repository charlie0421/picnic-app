import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/pangle_ads_helper.dart';

void main() {
  group('PangleAdsHelper.classifyEvent', () {
    test('classifies onAdShown correctly', () {
      expect(
        PangleAdsHelper.classifyEvent('onAdShown'),
        PangleAdsHelper.adShownEvent,
      );
    });

    test('classifies onAdClicked correctly', () {
      expect(
        PangleAdsHelper.classifyEvent('onAdClicked'),
        PangleAdsHelper.adClickedEvent,
      );
    });

    test('classifies onAdDismissed correctly', () {
      expect(
        PangleAdsHelper.classifyEvent('onAdDismissed'),
        PangleAdsHelper.adDismissedEvent,
      );
    });

    test('classifies onAdClosed as adDismissed', () {
      expect(
        PangleAdsHelper.classifyEvent('onAdClosed'),
        PangleAdsHelper.adDismissedEvent,
      );
    });

    test('classifies onRewardEarned correctly', () {
      expect(
        PangleAdsHelper.classifyEvent('onRewardEarned'),
        PangleAdsHelper.rewardEarnedEvent,
      );
    });

    test('classifies onRewardFailed correctly', () {
      expect(
        PangleAdsHelper.classifyEvent('onRewardFailed'),
        PangleAdsHelper.rewardFailedEvent,
      );
    });

    test('returns null for unknown event', () {
      expect(PangleAdsHelper.classifyEvent('unknownEvent'), isNull);
    });

    test('returns null for empty string', () {
      expect(PangleAdsHelper.classifyEvent(''), isNull);
    });

    test('is case-sensitive', () {
      expect(PangleAdsHelper.classifyEvent('ONADSHOWN'), isNull);
      expect(PangleAdsHelper.classifyEvent('onAdshown'), isNull);
    });
  });

  group('PangleAdsHelper.parseRewardArgs', () {
    test('parses valid map arguments', () {
      final result = PangleAdsHelper.parseRewardArgs({
        'rewardName': 'coin',
        'rewardAmount': 10,
      });
      expect(result, isNotNull);
      expect(result!['rewardName'], 'coin');
      expect(result['rewardAmount'], 10);
    });

    test('returns null for non-map arguments', () {
      expect(PangleAdsHelper.parseRewardArgs('not a map'), isNull);
    });

    test('returns null for null arguments', () {
      expect(PangleAdsHelper.parseRewardArgs(null), isNull);
    });

    test('returns null for int arguments', () {
      expect(PangleAdsHelper.parseRewardArgs(42), isNull);
    });

    test('returns null for list arguments', () {
      expect(PangleAdsHelper.parseRewardArgs([1, 2, 3]), isNull);
    });

    test('handles empty map', () {
      final result = PangleAdsHelper.parseRewardArgs({});
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('handles map with various value types', () {
      final result = PangleAdsHelper.parseRewardArgs({
        'string': 'value',
        'int': 42,
        'double': 3.14,
        'bool': true,
        'null': null,
      });
      expect(result, isNotNull);
      expect(result!['string'], 'value');
      expect(result['int'], 42);
      expect(result['double'], 3.14);
      expect(result['bool'], true);
      expect(result['null'], isNull);
    });
  });

  group('PangleAdsHelper.extractErrorMessage', () {
    test('extracts error message from valid map', () {
      final result = PangleAdsHelper.extractErrorMessage({
        'errorMessage': 'Network timeout',
      });
      expect(result, 'Network timeout');
    });

    test('returns default message when errorMessage key is missing', () {
      final result = PangleAdsHelper.extractErrorMessage({'other': 'data'});
      expect(result, '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958');
    });

    test('returns default message when errorMessage is null', () {
      final result = PangleAdsHelper.extractErrorMessage({
        'errorMessage': null,
      });
      expect(result, '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958');
    });

    test('returns default message for non-map arguments', () {
      expect(
        PangleAdsHelper.extractErrorMessage('string'),
        '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958',
      );
    });

    test('returns default message for null arguments', () {
      expect(
        PangleAdsHelper.extractErrorMessage(null),
        '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958',
      );
    });

    test('returns default message for empty map', () {
      expect(
        PangleAdsHelper.extractErrorMessage({}),
        '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958',
      );
    });

    test('extracts empty string error message', () {
      final result = PangleAdsHelper.extractErrorMessage({'errorMessage': ''});
      expect(result, '');
    });
  });
}
